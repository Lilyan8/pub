" Comment {{{
function CHelpFunc()
  echomsg "Uasge for Coding verilog command"
  echomsg "   Ade     : Add sequence register at current line"
  echomsg "   Adc     : Add combination register at current line"
  echomsg "   Ads     : Add sequence & next combination register at current line"
  echomsg "   Adw     : Add wire at current line"
  echomsg "             Ade/Adc/Ads/Adw width name"
  echomsg "   Ins     : Insert special code. such as:"
  echomsg "             Ins case xxx"
  echomsg "             Ins for i 100"
  echomsg "             Ins genf i 100"
  echomsg "             Ins geni i 3"
  echomsg "             Ins def AXI_CH0"
  echomsg "   Intf    : Insert special interface. such as:"
  echomsg "             Intf apbs m0 dma"
  echomsg "             Intf apbm m0 dma"
  echomsg "             Intf axis m0 dma"
  echomsg "             Intf axim m0 dma"
  echomsg "             Intf ahbs m0 dma"
  echomsg "             Intf ahbm m0 dma"
  echomsg "   Valign  : verilog format align"
  echomsg "   LJ      : Module instance for normal"
  echomsg "   LJG     : Module instance for generate"
  echomsg "   Rio     : Reverse interface such as: input -> output"
  echomsg "   Acc     : index increase"
  echomsg "   Dec     : index decrease"
  echomsg "   ZR      : assign 0 to output signals"
  echomsg "------------------------ misc ----------------------"
  echomsg "   Delbank : delete empty bank line."
endfunction
command -nargs=* CHelp :call CHelpFunc()
"" }}}
" Constant parameter {{{
let s:align_intf_space_len           = 5  - 1
let s:align_intf_signal              = 50 - 1
let s:align_intf_parameter           = 40 - 1
let s:align_inst_left                = 40 - 1
let s:align_inst_right               = 80 - 1
let s:align_inner_signal             = 50 - 1
let s:align_equal_mark               = 25 - 1
let s:align_cmmt_mark                = 85 - 1
let s:align_tab_indent               = &sw

let vim_para                         = $VIM_PARA
let vim_para_list                    = split(vim_para,'/')
let s:clk_name                       = vim_para_list[4]
let s:rst_name                       = vim_para_list[5]

let s:constant_declare                  = '^\s*\/\/ Constant Parameter'
let s:template_declare                 = '^\s*\/\/ Internal Signals Declarations'
let s:template_main_bgn                = '^\s*\/\/ Main Code'
let s:template_main_end                = '^\s*\/\/ Assertion Declarations'
let s:def_mark                         = '// DONT TOUCH'
let s:def_mark_srch                    = '\s*\/\/ DONT TOUCH'


let s:bank_mdy = [0,0]
let s:align_mdy = [0,s:align_cmmt_mark]

let s:pat_param = '^\s*\(parameter\|localparam\)'
let s:pat_width = '\(\[.\{-}\]\)'
let s:pat_declare = '\(reg\|wire\)'
let s:pat_intf = '^\s*\(input \|output\|inout \)'

let s:pat_signal = '\([^ ,;=]*\)'
let s:pat_equal = '[^><=]\(<=\|=\)[^=]'
let s:pat_maker = '\([;,]\)'

let s:pat_value = '\(.\{-}\)\s*'
let s:pat_cmt = '\(\/\/.*\)'

let s:pat_inst = '^\s*\(\.\)'
let s:pat_instsig = '\([^ ()]*\)'
let s:pat_instval = '\([^()]*\)'
let s:pat_instmkr = '\([()]\)'

let s:pat_assign = '^\s*\(assign\)'
let s:pat_seqsig = '^\(.\{-}\)\(<=\|=\)'


" }}}
" common function {{{

function CommentEraser(line)
  let matchStr = ""
  let cmt = ""
  if a:line =~ '^\s*\(\/\/\|\/\*\|\*\)'
    let matchStr = a:line
    let cmt = ""
  else
    let matchStr = substitute(a:line,s:pat_cmt,"","")
    let cmt = matchstr(a:line,s:pat_cmt)
  endif
  return [matchStr,cmt]
endfunction

function MakerEraser(line)
  let matchStr = ""
  let maker    = ""
  if a:line =~ s:pat_maker.'\s*$'
    let matchStr = substitute(a:line,s:pat_maker.'\s*$',"","")
    let maker    = substitute(a:line,'^.*'.s:pat_maker.'.*$','\1',"")
  else
    let matchStr = a:line
    let maker    = ""
  endif
  return [matchStr,maker]
endfunction

function PatGen(subpat)
  let rpl = ''
  for i in a:subpat
    let rpl = rpl.i.'\s*'
  endfor
  let rpl = rpl.'$'
  return rpl
endfunction

function SubstrGet(line,pat,plen)
    let rpl = ""
    let maker = ""
    let cmmt = ""
    let mpat = []
    let [rpl,cmmt] = CommentEraser(a:line)
    let [rpl,maker] = MakerEraser(rpl)
    let mpat = matchlist(rpl,a:pat)
    if mpat != []
      let mpat = mpat[1:a:plen]
      call add(mpat,maker)
      call add(mpat,cmmt)
    endif
    return mpat
endfunction

function PrintLineList(rpl)
  let rpl_list = a:rpl
  let idx      = line('.')
  let rpl_len  = len(rpl_list)
  for i in range(rpl_len)
    let lid = i + idx
    call append(lid,rpl_list[i])
  endfor
endfunction

function AlignPrintLine(opts,bank,align)
  let opts_list = a:opts
  let bank_list = a:bank
  let align_list = a:align

  let opts_len = len(opts_list)
  let rpl = ""
  for i in range(opts_len)
    let tmpalign = align_list[i]
    let tmpbank  = bank_list[i]
    let tmpopts  = opts_list[i]
    " jion opts
    if tmpalign > 0
      let tmplen = len(rpl)
      if tmplen > tmpalign
        let rpl = rpl.' '.tmpopts
      else
        let rpl = rpl.repeat(' ',(tmpalign-tmplen)).tmpopts
      endif
    else
      let rpl = rpl.tmpopts
    endif
    " add bank
    if tmpbank > 0 && tmpopts != ""
      let rpl = rpl.' '
    endif
  endfor
  return rpl
endfunction

function DelRepBank()
  if getline(".") == "" && getline(".") == getline(line(".") + 1)
    norm dd
  endif
endfunction

function DelAllRepBank()
  g/^/call DelRepBank()
endfunction
command -nargs=* Delbank :call DelAllRepBank()




" }}}
" align function {{{
function ParamAlign()
  let mpat =[]
  let cline = ""
  let rline = ""
  "let bgn_const = search(s:constant_declare,'n')
  let pat_list = [s:pat_param,s:pat_width.'\?',s:pat_signal,s:pat_equal,s:pat_value]
  let bank_list = [1,1,1,1,0]  + s:bank_mdy
  let align_list = [s:align_intf_space_len,0,0,s:align_intf_parameter,0] + s:align_mdy
  let pat = PatGen(pat_list)
  let pat_len = len(pat_list)
  for i in range(1,line('$'))
    let cline = getline(i)
    let mpat = SubstrGet(cline,pat,pat_len)
    if mpat != []
      let rline = AlignPrintLine(mpat,bank_list,align_list)
      if cline != rline && rline != ""
        call setline(i,rline)
      endif
    endif
  endfor

endfunction

function IntfAlign()
  let mpat =[]
  let cline = ""
  let rline = ""
  "let bgn_const = search(s:constant_declare,'n')
  let pat_list = [s:pat_intf,s:pat_declare.'\?',s:pat_width.'\?',s:pat_signal]
  let bank_list = [1,1,1,0] + s:bank_mdy
  let pat = PatGen(pat_list)
  let pat_len = len(pat_list)
  "for i in range(1,bgn_const)
  for i in range(1,line('$'))
    let cline = getline(i)
    let mpat = SubstrGet(cline,pat,pat_len)
    if mpat != []
      let align_width_len   = s:align_inner_signal - len(mpat[2]) - 1
      let align_list = [s:align_intf_space_len,0,align_width_len,s:align_intf_signal] + s:align_mdy
      let rline = AlignPrintLine(mpat,bank_list,align_list)
      if cline != rline && rline != ""
        call setline(i,rline)
      endif
    endif
  endfor

endfunction

function DeclareAlign()
  let mpat =[]
  let cline = ""
  let rline = ""
  "let bgn_declare = search(s:template_declare,'n')
  "let end_declare = search(s:template_main_bgn,'n')
  let pat_list = ['^\s*'.s:pat_declare,s:pat_width.'\?',s:pat_signal]
  let bank_list = [1,1,0] + s:bank_mdy
  let pat = PatGen(pat_list)
  let pat_len = len(pat_list)
  "for i in range(bgn_declare,end_declare)
  for i in range(1,line('$'))
    let cline = getline(i)
    let mpat = SubstrGet(cline,pat,pat_len)
    if mpat != []
      let align_width_len   = s:align_inner_signal - len(mpat[1]) - 1
      let align_list = [0,align_width_len,s:align_inner_signal] + s:align_mdy
      let rline = AlignPrintLine(mpat,bank_list,align_list)
      if cline != rline && rline != ""
        call setline(i,rline)
      endif
    endif
  endfor

endfunction


function EqualAlign()
  let mpat =[]
  let cline = ""
  let rline = ""
  let pat_list = ['\(^\s*[^ ,;=]*\)',s:pat_equal,s:pat_value]
  let bank_list = [1,1,0] + s:bank_mdy
  let align_list = [0,s:align_equal_mark,0] + s:align_mdy
  let pat = PatGen(pat_list)
  let pat_len = len(pat_list)
  for i in range(1,line('$'))


    let cline = getline(i)
    if cline !~ '\(for\|if\)'
      let mpat = SubstrGet(cline,pat,pat_len)
      if mpat != []
        let rline = AlignPrintLine(mpat,bank_list,align_list)
        if cline != rline && rline != ""
          call setline(i,rline)
        endif
      endif
    endif
  endfor

endfunction

function AssignAlign()
  let mpat =[]
  let cline = ""
  let rline = ""
  let pat_list = ['\(^\s*assign\)',s:pat_signal,s:pat_equal,s:pat_value]
  let bank_list = [1,1,1,0] + s:bank_mdy
  let align_list = [0,0,s:align_equal_mark,0] + s:align_mdy
  let pat = PatGen(pat_list)
  let pat_len = len(pat_list)
  for i in range(1,line('$'))
    let cline = getline(i)
    let mpat = SubstrGet(cline,pat,pat_len)
    if mpat != []
      let rline = AlignPrintLine(mpat,bank_list,align_list)
      if cline != rline && rline != ""
        call setline(i,rline)
      endif
    endif
  endfor

endfunction

function InstAlign()
  let mpat =[]
  let cline = ""
  let rline = ""
  let pat_list = ['^\s*\(\.\)',s:pat_signal,'\((\)',s:pat_value,'\()\)']
  let bank_list = [0,0,1,0,0]  + s:bank_mdy
  let align_list = [s:align_intf_space_len,0,s:align_inst_left,0,s:align_inst_right] + s:align_mdy
  let pat = PatGen(pat_list)
  let pat_len = len(pat_list)
  for i in range(1,line('$'))
  "for i in range(128,129)
    let cline = getline(i)
    let mpat = SubstrGet(cline,pat,pat_len)
    if mpat != []
      let rline = AlignPrintLine(mpat,bank_list,align_list)
      if cline != rline && rline != ""
        call setline(i,rline)
      endif
    endif
  endfor

endfunction

function VerilogAlign()
  call cursor(1,1)
  " parameter
  call ParamAlign()
  " interface
  call IntfAlign()
  " declare
  call DeclareAlign()
  " equal
  call EqualAlign()
  call AssignAlign()
  " instance
  call InstAlign()
  " misc
  call DelAllRepBank()
  g/\s*$//
  norm gg
endfunction



command -nargs=* Valign :call VerilogAlign()
" }}}
" code function{{{
function InstModule(mode) range
  if a:mode == 0
    let dim = ""
  else
    let dim = '[i]'
  endif
  let opts_list =[]
  let bank_list = [0,0,0,1,0]  + s:bank_mdy
  let align_list = [s:align_intf_space_len,0,s:align_inst_left,0,s:align_inst_right] + s:align_mdy
  for i in range(a:firstline,a:lastline)
    let rline = ""
    let cline = getline(i)
    if cline =~ '^\s*module'
      let rline = substitute(cline,'^\s*module\s*\([^ ].*\).*$','\1','')
    elseif cline =~ s:pat_param
      let pat_list = [s:pat_param,s:pat_width.'\?',s:pat_signal,s:pat_equal,s:pat_value]
      let pat = PatGen(pat_list)
      let pat_len = len(pat_list)
      let mpat = SubstrGet(cline,pat,pat_len)
      let opts_list = ['.',mpat[2],'(',mpat[2],')',mpat[5],mpat[6]]
      let rline = AlignPrintLine(opts_list,bank_list,align_list)
    elseif cline =~ s:pat_intf
      let pat_list = [s:pat_intf,s:pat_declare.'\?',s:pat_width.'\?',s:pat_signal]
      let pat = PatGen(pat_list)
      let pat_len = len(pat_list)
      let mpat = SubstrGet(cline,pat,pat_len)
      let instname = mpat[3].dim
      let opts_list = ['.',mpat[3],'(',instname,')',mpat[4],mpat[5]]
      let rline = AlignPrintLine(opts_list,bank_list,align_list)
    endif
    if cline != rline && rline != ""
      call setline(i,rline)
    endif
  endfor
endfunction

command -nargs=* -range=% LJ  :<line1>,<line2>call InstModule(0)
command -nargs=* -range=% LJG :<line1>,<line2>call InstModule(1)

function InitSignal() range
  let pat_list = ['^\s*\(output\|inout\)',s:pat_declare.'\?\s',s:pat_width.'\?',s:pat_signal]
  let bank_list = [1,1,1,0] + s:bank_mdy
  let align_list = [s:align_intf_space_len,0,0,s:align_intf_signal] + s:align_mdy
  let pat = PatGen(pat_list)
  echo pat
  let pat_len = len(pat_list)
  for i in range(a:lastline,a:firstline,-1)
    let rline = ""
    let cline = getline(i)
    let mpat = SubstrGet(cline,pat,pat_len)
    "echo mpat
    if mpat != []
      let width = mpat[2]
      if mpat[2] == ""
        let width = 1
      elseif mpat[2] =~ '-1\s*:'
        let width = substitute(mpat[2],'\s*\[\(.\{-}\)-1\s*:.*$','\1',"")
      else
        let width = substitute(mpat[2],'\s*\[\(.\{-}\)\s*:.*$','\1',"")
        if width - 1 >= 0
          let width = width + 1
        else
          let width = printf("(%s+1)",width)
        endif
      endif
      let rline = printf("assign %s = {%s{1'b0}};",mpat[3],width)
      cal setline(i,rline)
    else
      exec i."del"
    endif
  endfor
endfunction

command -nargs=* -range=% ZR  :<line1>,<line2>call InitSignal()



" wire decaluration
function DecWireFunc(width,name,arrow)
  let rpl = []
  let widthdec = a:width - 1
  let arrowdec = a:arrow - 1

  " widthSpace
  if a:width == 1                                 " width equal number 1
    let widthSpacestr = ""
  elseif widthdec > 0                             " width is number
    let widthSpacestr = printf("[%s:0]",widthdec)
  else                                            " width is letter
    let widthSpacestr = printf("[%s-1:0]",a:width)
  endif
  " arrowSpace
  if a:arrow == 1                                 " arrow equal number 1
    let arrowSpacestr = ""
    let arrowInststr = ""
  elseif arrowdec > 0                             " arrow is number
    let arrowSpacestr = printf("[%s:0]",arrowdec)
    let arrowInststr = "[i]"
  else                                            " arrow is letter
    let arrowSpacestr = printf("[%s-1:0]",a:arrow)
    let arrowInststr = "[i]"
  endif

  " wire [1:0] xxx[xs-1:0];
  let align_width_len   = s:align_inner_signal - len(widthSpacestr) - 1
  let opts_list   = ['wire',widthSpacestr,a:name,arrowSpacestr,';']
  let bank_list   = [1,1,0,0,0]                                      " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,align_width_len,s:align_inner_signal,0,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  " assign xxx =
  let inst_name   = a:name.arrowInststr
  let opts_list   = ['assign',inst_name,'=']
  let bank_list   = [1,1,0]                                    " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,0,s:align_equal_mark]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))

  " print text
  call PrintLineList(rpl)
endfunction

" sequence register decaluration
function DecSregFunc(width,name,arrow)
  let rpl = []
  let widthdec = a:width - 1
  let arrowdec = a:arrow - 1

  " widthSpace
  if a:width == 1                                 " width equal number 1
    let widthSpacestr = ""
  elseif widthdec > 0                             " width is number
    let widthSpacestr = printf("[%s:0]",widthdec)
  else                                            " width is letter
    let widthSpacestr = printf("[%s-1:0]",a:width)
  endif
  " arrowSpace
  if a:arrow == 1                                 " arrow equal number 1
    let arrowSpacestr = ""
    let arrowInststr = ""
  elseif arrowdec > 0                             " arrow is number
    let arrowSpacestr = printf("[%s:0]",arrowdec)
    let arrowInststr = "[i]"
  else                                            " arrow is letter
    let arrowSpacestr = printf("[%s-1:0]",a:arrow)
    let arrowInststr = "[i]"
  endif

  " reg [1:0] xxx[xs-1:0];
  let align_width_len   = s:align_inner_signal - len(widthSpacestr) - 1
  let opts_list   = ['reg',widthSpacestr,a:name,arrowSpacestr,';']
  let bank_list   = [1,1,0,0,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,align_width_len,s:align_inner_signal,0,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  " always@(posedge aclk or negedge areset_n)
  " begin : XXX_PROC
  " if (areset_n == 1'b0)
  "   xxx           <= {nn{1'b0}};
  " else
  "   xxx           <= ;
  " end
  call add(rpl,printf("always @(posedge %s or negedge %s)",s:clk_name,s:rst_name))
  call add(rpl,printf("begin : %s_PROC",toupper(a:name)))
  call add(rpl,printf("  if (%s == 1'b0)",s:rst_name))
  let inst_name   = a:name.arrowInststr
  let inst_zero   = printf("{%s{1'b0}};",a:width)
  let opts_list   = [repeat(' ',2*s:align_tab_indent),inst_name,'<=',inst_zero]
  let bank_list   = [0,1,1,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,0,s:align_equal_mark,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  call add(rpl,"  else")
  let opts_list   = [repeat(' ',2*s:align_tab_indent),inst_name,'<=',';']
  let bank_list   = [0,1,1,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,0,s:align_equal_mark,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  call add(rpl,"end")

  " print text
  call PrintLineList(rpl)
endfunction
" combination register decaluration
function DecCregFunc(width,name,arrow)
  let rpl = []
  let widthdec = a:width - 1
  let arrowdec = a:arrow - 1

  " widthSpace
  if a:width == 1                                 " width equal number 1
    let widthSpacestr = ""
  elseif widthdec > 0                             " width is number
    let widthSpacestr = printf("[%s:0]",widthdec)
  else                                            " width is letter
    let widthSpacestr = printf("[%s-1:0]",a:width)
  endif
  " arrowSpace
  if a:arrow == 1                                 " arrow equal number 1
    let arrowSpacestr = ""
    let arrowInststr = ""
  elseif arrowdec > 0                             " arrow is number
    let arrowSpacestr = printf("[%s:0]",arrowdec)
    let arrowInststr = "[i]"
  else                                            " arrow is letter
    let arrowSpacestr = printf("[%s-1:0]",a:arrow)
    let arrowInststr = "[i]"
  endif

  " reg [1:0] xxx[xs-1:0];
  let align_width_len   = s:align_inner_signal - len(widthSpacestr) - 1
  let opts_list   = ['reg',widthSpacestr,a:name,arrowSpacestr,';']
  let bank_list   = [1,1,0,0,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,align_width_len,s:align_inner_signal,0,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  " always@(*)
  " begin : XXX_PROC
  " if ()
  "   xxx           <= ;
  " else
  "   xxx           <= {n{1'b0}};
  " end
  call add(rpl,"always @*")
  call add(rpl,printf("begin : %s_PROC",toupper(a:name)))
  call add(rpl,"  if ()")
  let inst_name   = a:name.arrowInststr
  let inst_zero   = printf("{%s{1'b0}};",a:width)
  let opts_list   = [repeat(' ',2*s:align_tab_indent),inst_name,'=',';']
  let bank_list   = [0,1,1,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,0,s:align_equal_mark,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  call add(rpl,"  else")
  let opts_list   = [repeat(' ',2*s:align_tab_indent),inst_name,'=',inst_zero]
  let bank_list   = [0,1,1,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,0,s:align_equal_mark,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  call add(rpl,"end")

  " print text
  call PrintLineList(rpl)
endfunction

" sequence & next register decaluration
function DecSCregFunc(width,name,arrow)
  let rpl = []
  let widthdec = a:width - 1
  let arrowdec = a:arrow - 1

  " widthSpace
  if a:width == 1                                 " width equal number 1
    let widthSpacestr = ""
  elseif widthdec > 0                             " width is number
    let widthSpacestr = printf("[%s:0]",widthdec)
  else                                            " width is letter
    let widthSpacestr = printf("[%s-1:0]",a:width)
  endif
  " arrowSpace
  if a:arrow == 1                                 " arrow equal number 1
    let arrowSpacestr = ""
    let arrowInststr = ""
  elseif arrowdec > 0                             " arrow is number
    let arrowSpacestr = printf("[%s:0]",arrowdec)
    let arrowInststr = "[i]"
  else                                            " arrow is letter
    let arrowSpacestr = printf("[%s-1:0]",a:arrow)
    let arrowInststr = "[i]"
  endif

  let seq_req = a:name
  let nxt_req = 'nxt_'.seq_req
  " reg [1:0] xxx[xs-1:0];
  let align_width_len   = s:align_inner_signal - len(widthSpacestr) - 1
  let opts_list   = ['reg',widthSpacestr,seq_req,arrowSpacestr,';']
  let bank_list   = [1,1,0,0,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,align_width_len,s:align_inner_signal,0,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  " reg [1:0] nxt_xxx[xs-1:0];
  let opts_list   = ['reg',widthSpacestr,nxt_req,arrowSpacestr,';']
  let bank_list   = [1,1,0,0,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,align_width_len,s:align_inner_signal,0,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  " always@(posedge aclk or negedge areset_n)
  " begin : XXX_PROC
  " if (areset_n == 1'b0)
  "   xxx           <= {nn{1'b0}};
  " else
  "   xxx           <= ;
  " end
  call add(rpl,printf("always @(posedge %s or negedge %s)",s:clk_name,s:rst_name))
  call add(rpl,printf("begin : %s_PROC",toupper(seq_req)))
  call add(rpl,printf("  if (%s == 1'b0)",s:rst_name))
  let inst_name   = seq_req.arrowInststr
  let nxt_name    = nxt_req.arrowInststr.';'
  let inst_zero   = printf("{%s{1'b0}};",a:width)
  let opts_list   = [repeat(' ',2*s:align_tab_indent),inst_name,'<=',inst_zero]
  let bank_list   = [0,1,1,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,0,s:align_equal_mark,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  call add(rpl,"  else")
  let opts_list   = [repeat(' ',2*s:align_tab_indent),inst_name,'<=',nxt_name]
  let bank_list   = [0,1,1,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,0,s:align_equal_mark,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  call add(rpl,"end")
  call add(rpl,"")
  " always@(*)
  " begin : XXX_PROC
  " if ()
  "   xxx           <= ;
  " else
  "   xxx           <= {n{1'b0}};
  " end
  call add(rpl,"always @*")
  call add(rpl,printf("begin : %s_PROC",toupper(nxt_req)))
  call add(rpl,"  if ()")
  let inst_name   = nxt_req.arrowInststr
  let inst_zero   = printf("{%s{1'b0}};",a:width)
  let opts_list   = [repeat(' ',2*s:align_tab_indent),inst_name,'=',';']
  let bank_list   = [0,1,1,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,0,s:align_equal_mark,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  call add(rpl,"  else")
  let opts_list   = [repeat(' ',2*s:align_tab_indent),inst_name,'=',inst_zero]
  let bank_list   = [0,1,1,0]                   " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,0,s:align_equal_mark,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  call add(rpl,"end")

  " print text
  call PrintLineList(rpl)
endfunction

function DecCell(mode,width,name,...)
  let param0 = 1
if exists("a:1")
  let param0 = a:1
endif

if a:mode == '0'     "wire
  call DecWireFunc(a:width,a:name,param0)
elseif a:mode == '1' " sequence register
  call DecSregFunc(a:width,a:name,param0)
elseif a:mode == '2' " combination register
  call DecCregFunc(a:width,a:name,param0)
elseif a:mode == '3'
  call DecSCregFunc(a:width,a:name,param0)
endif
endfunction

command -nargs=* Adw :call DecCell(0,<f-args>)
command -nargs=* Ade :call DecCell(1,<f-args>)
command -nargs=* Adc :call DecCell(2,<f-args>)
command -nargs=* Ads :call DecCell(3,<f-args>)

function InsCode(mode,...)
  let rpl = []
  let param0 = ""
  let param1 = ""
  let param2 = ""
if a:0 > 3
  echomsg "args is too more than 4!"
elseif a:0 > 2
  let param0 = a:1
  let param1 = a:2
  let param2 = a:3
elseif a:0 > 1
  let param0 = a:1
  let param1 = a:2
elseif a:0 > 0
  let param0 = a:1
endif

"--mode--+--------+--------+--------+--------+--------+--------+
"           case     for      genf     geni      AXI      APB
if a:mode == 'case'
  let rpl = DecCase(param0,param1)
elseif a:mode == 'for'
  let rpl = Decfor(param0,param1)
elseif a:mode == 'genf'
  let rpl = Decgenfor(param0,param1)
elseif a:mode == 'geni'
  let rpl = Decgenif(param0,param1)
elseif a:mode == 'AXI'
elseif a:mode == 'APB'
elseif a:mode == 'def'
  let rpl = Decgendef(param0)
endif
  " print text
  call PrintLineList(rpl)
endfunction
command -nargs=* Ins :call InsCode(<f-args>)

function InsertIntf(intf,ms,module)
  let lid = line('.')
  let rpl = []
  if a:intf == 'axim'
    call add(rpl,printf("output  [%s_AXI_ID_WIDTH-1:0]     %s_%s_awid    ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output  [%s_AXI_ADDR_WIDTH-1:0]   %s_%s_awaddr  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output  [7:0]                  %s_%s_awlen   ,",a:ms,a:module))
    call add(rpl,printf("output  [2:0]                  %s_%s_awsize  ,",a:ms,a:module))
    call add(rpl,printf("output  [1:0]                  %s_%s_awburst ,",a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_awlock  ,",a:ms,a:module))
    call add(rpl,printf("output  [3:0]                  %s_%s_awcache ,",a:ms,a:module))
    call add(rpl,printf("output  [2:0]                  %s_%s_awprot  ,",a:ms,a:module))
    call add(rpl,printf("output  [3:0]                  %s_%s_awqos   ,",a:ms,a:module))
    call add(rpl,printf("output  [%s_AXI_AWUSER_WIDTH-1:0] %s_%s_awuser  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_awvalid ,",a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_awready ,",a:ms,a:module))
    call add(rpl,printf("output  [%s_AXI_DATA_WIDTH-1:0]   %s_%s_wdata   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output  [%s_AXI_WSTRB_WIDTH-1:0]  %s_%s_wstrb   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_wlast   ,",a:ms,a:module))
    call add(rpl,printf("output  [%s_AXI_WUSER_WIDTH-1:0]  %s_%s_wuser   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_wvalid  ,",a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_wready  ,",a:ms,a:module))
    call add(rpl,printf("input  [%s_AXI_ID_WIDTH-1:0]      %s_%s_bid     ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input  [1:0]                   %s_%s_bresp   ,",a:ms,a:module))
    call add(rpl,printf("input  [%s_AXI_BUSER_WIDTH-1:0]   %s_%s_buser   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_bvalid  ,",a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_bready  ,",a:ms,a:module))
    call add(rpl,printf("output  [%s_AXI_ID_WIDTH-1:0]     %s_%s_arid    ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output  [%s_AXI_ADDR_WIDTH-1:0]   %s_%s_araddr  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output  [7:0]                  %s_%s_arlen   ,",a:ms,a:module))
    call add(rpl,printf("output  [2:0]                  %s_%s_arsize  ,",a:ms,a:module))
    call add(rpl,printf("output  [1:0]                  %s_%s_arburst ,",a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_arlock  ,",a:ms,a:module))
    call add(rpl,printf("output  [3:0]                  %s_%s_arcache ,",a:ms,a:module))
    call add(rpl,printf("output  [2:0]                  %s_%s_arprot  ,",a:ms,a:module))
    call add(rpl,printf("output  [3:0]                  %s_%s_arqos   ,",a:ms,a:module))
    call add(rpl,printf("output  [%s_AXI_ARUSER_WIDTH-1:0] %s_%s_aruser  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_arvalid ,",a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_arready ,",a:ms,a:module))
    call add(rpl,printf("input  [%s_AXI_ID_WIDTH-1:0]      %s_%s_rid     ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input  [%s_AXI_DATA_WIDTH-1:0]    %s_%s_rdata   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input  [1:0]                   %s_%s_rresp   ,",a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_rlast   ,",a:ms,a:module))
    call add(rpl,printf("input  [%s_AXI_RUSER_WIDTH-1:0]   %s_%s_ruser   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_rvalid  ,",a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_rready  ,",a:ms,a:module))
  elseif a:intf == 'axis'
    call add(rpl,printf("input   [%s_AXI_ID_WIDTH-1:0]     %s_%s_awid    ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input   [%s_AXI_ADDR_WIDTH-1:0]   %s_%s_awaddr  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input   [7:0]                  %s_%s_awlen   ,",a:ms,a:module))
    call add(rpl,printf("input   [2:0]                  %s_%s_awsize  ,",a:ms,a:module))
    call add(rpl,printf("input   [1:0]                  %s_%s_awburst ,",a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_awlock  ,",a:ms,a:module))
    call add(rpl,printf("input   [3:0]                  %s_%s_awcache ,",a:ms,a:module))
    call add(rpl,printf("input   [2:0]                  %s_%s_awprot  ,",a:ms,a:module))
    call add(rpl,printf("input   [3:0]                  %s_%s_awqos   ,",a:ms,a:module))
    call add(rpl,printf("input   [%s_AXI_AWUSER_WIDTH-1:0] %s_%s_awuser  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_awvalid ,",a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_awready ,",a:ms,a:module))
    call add(rpl,printf("input   [%s_AXI_DATA_WIDTH-1:0]   %s_%s_wdata   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input   [%s_AXI_WSTRB_WIDTH-1:0]  %s_%s_wstrb   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_wlast   ,",a:ms,a:module))
    call add(rpl,printf("input   [%s_AXI_WUSER_WIDTH-1:0]  %s_%s_wuser   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_wvalid  ,",a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_wready  ,",a:ms,a:module))
    call add(rpl,printf("output [%s_AXI_ID_WIDTH-1:0]      %s_%s_bid     ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output [1:0]                   %s_%s_bresp   ,",a:ms,a:module))
    call add(rpl,printf("output [%s_AXI_BUSER_WIDTH-1:0]   %s_%s_buser   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_bvalid  ,",a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_bready  ,",a:ms,a:module))
    call add(rpl,printf("input   [%s_AXI_ID_WIDTH-1:0]     %s_%s_arid    ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input   [%s_AXI_ADDR_WIDTH-1:0]   %s_%s_araddr  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input   [7:0]                  %s_%s_arlen   ,",a:ms,a:module))
    call add(rpl,printf("input   [2:0]                  %s_%s_arsize  ,",a:ms,a:module))
    call add(rpl,printf("input   [1:0]                  %s_%s_arburst ,",a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_arlock  ,",a:ms,a:module))
    call add(rpl,printf("input   [3:0]                  %s_%s_arcache ,",a:ms,a:module))
    call add(rpl,printf("input   [2:0]                  %s_%s_arprot  ,",a:ms,a:module))
    call add(rpl,printf("input   [3:0]                  %s_%s_arqos   ,",a:ms,a:module))
    call add(rpl,printf("input   [%s_AXI_ARUSER_WIDTH-1:0] %s_%s_aruser  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_arvalid ,",a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_arready ,",a:ms,a:module))
    call add(rpl,printf("output [%s_AXI_ID_WIDTH-1:0]      %s_%s_rid     ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output [%s_AXI_DATA_WIDTH-1:0]    %s_%s_rdata   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output [1:0]                   %s_%s_rresp   ,",a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_rlast   ,",a:ms,a:module))
    call add(rpl,printf("output [%s_AXI_RUSER_WIDTH-1:0]   %s_%s_ruser   ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output                         %s_%s_rvalid  ,",a:ms,a:module))
    call add(rpl,printf("input                          %s_%s_rready  ,",a:ms,a:module))
  elseif a:intf == 'apbm'
    call add(rpl,printf("output   [%s_APB_ADDR_WIDTH-1:0]     %s_%s_paddr  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output   [2:0]                    %s_%s_pprot  ,",a:ms,a:module))
    call add(rpl,printf("output                            %s_%s_psel   ,",a:ms,a:module))
    call add(rpl,printf("output                            %s_%s_penable,",a:ms,a:module))
    call add(rpl,printf("output                            %s_%s_pwrite ,",a:ms,a:module))
    call add(rpl,printf("output   [%s_APB_DATA_WIDTH-1:0]     %s_%s_pwdata ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output   [%s_APB_USER_WIDTH-1:0]     %s_%s_puser  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input                             %s_%s_pready ,",a:ms,a:module))
    call add(rpl,printf("input   [%s_APB_DATA_WIDTH-1:0]     %s_%s_prdata ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input                            %s_%s_pslverr,",a:ms,a:module))
  elseif a:intf == 'apbs'
    call add(rpl,printf("input    [%s_APB_ADDR_WIDTH-1:0]     %s_%s_paddr  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input    [2:0]                    %s_%s_pprot  ,",a:ms,a:module))
    call add(rpl,printf("input                             %s_%s_psel   ,",a:ms,a:module))
    call add(rpl,printf("input                             %s_%s_penable,",a:ms,a:module))
    call add(rpl,printf("input                             %s_%s_pwrite ,",a:ms,a:module))
    call add(rpl,printf("input    [%s_APB_DATA_WIDTH-1:0]     %s_%s_pwdata ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input    [%s_APB_USER_WIDTH-1:0]     %s_%s_puser  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output                            %s_%s_pready ,",a:ms,a:module))
    call add(rpl,printf("output    [%s_APB_DATA_WIDTH-1:0]     %s_%s_prdata ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output                             %s_%s_pslverr,",a:ms,a:module))
  elseif a:intf == 'ahbm'
    call add(rpl,printf("output   [%s_AHB_ADDR_WIDTH-1:0]     %s_%s_haddr  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output                            %s_%s_hbusreq,",a:ms,a:module))
    call add(rpl,printf("output   [2:0]                    %s_%s_hburst,",a:ms,a:module))
    call add(rpl,printf("output                            %s_%s_hlock,",a:ms,a:module))
    call add(rpl,printf("output   [3:0]                    %s_%s_hprot,",a:ms,a:module))
    call add(rpl,printf("output   [2:0]                    %s_%s_hsize,",a:ms,a:module))
    call add(rpl,printf("output   [1:0]                    %s_%s_htrans ,",a:ms,a:module))
    call add(rpl,printf("output   [%s_AHB_DATA_WIDTH-1:0]     %s_%s_hwdata ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output                            %s_%s_hwrite,",a:ms,a:module))
    call add(rpl,printf("input    [%s_AHB_DATA_WIDTH-1:0]     %s_%s_hrdata  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input    [1:0]                    %s_%s_hresp  ,",a:ms,a:module))
    call add(rpl,printf("input                             %s_%s_hready,",a:ms,a:module))
    call add(rpl,printf("input                             %s_%s_hgrant,",a:ms,a:module))
  elseif a:intf == 'ahbs'
    call add(rpl,printf("input    [%s_AHB_ADDR_WIDTH-1:0]     %s_%s_haddr  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("input    [2:0]                    %s_%s_hburst,",a:ms,a:module))
    call add(rpl,printf("input    [3:0]                    %s_%s_hprot,",a:ms,a:module))
    call add(rpl,printf("input    [2:0]                    %s_%s_hsize,",a:ms,a:module))
    call add(rpl,printf("input    [1:0]                    %s_%s_htrans ,",a:ms,a:module))
    call add(rpl,printf("input                             %s_%s_hsel,",a:ms,a:module))
    call add(rpl,printf("input                             %s_%s_hwrite,",a:ms,a:module))
    call add(rpl,printf("input                             %s_%s_hready,",a:ms,a:module))
    call add(rpl,printf("input    [%s_AHB_DATA_WIDTH-1:0]     %s_%s_hwdata ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output    [%s_AHB_DATA_WIDTH-1:0]    %s_%s_hrdata  ,",toupper(a:ms),a:ms,a:module))
    call add(rpl,printf("output    [1:0]                   %s_%s_hresp  ,",a:ms,a:module))
    call add(rpl,printf("output                            %s_%s_hreadyout,",a:ms,a:module))
  endif
  for i in range(len(rpl))
    call append(i+lid,rpl[i])
  endfor
endfunction

command -nargs=* Intf :call InsertIntf(<f-args>)

function DecCase(sel,data)
  let rpl = []
  if a:data == ""
    let bus = "data"
  else
    let bus = a:data
  endif

  call add(rpl,printf("case (%s)",a:sel))
  call add(rpl,repeat(' ',s:align_tab_indent)."3'h0    : begin")
  let opts_list   = [repeat(' ',s:align_tab_indent*2),bus,'<=',';']
  let bank_list   = [0,1,1,0]                                    " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,0,s:align_equal_mark,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  call add(rpl,repeat(' ',s:align_tab_indent)."end")
  call add(rpl,repeat(' ',s:align_tab_indent)."default : begin")
  let opts_list   = [repeat(' ',s:align_tab_indent*2),bus,'<=',';']
  let bank_list   = [0,1,1,0]                                    " 1: a bank after tag; 0: no bank after tag
  let align_list  = [0,0,s:align_equal_mark,0]                   " 1: a bank after tag; 0: no bank after tag
  call add(rpl,AlignPrintLine(opts_list,bank_list,align_list))
  call add(rpl,repeat(' ',s:align_tab_indent)."end")
  call add(rpl,"endcase")

  return rpl
endfunction

function Decfor(var,thld)
  let rpl = []
  call add(rpl,printf("for (%s = 0; %s < %s; %s = %s + 1)",a:var,a:var,a:thld,a:var,a:var))
  call add(rpl,"begin")
  call add(rpl,"")
  call add(rpl,"end")
  return rpl
endfunction

function Decgenfor(var,thld)
  let rpl = []
  call add(rpl,"generate")
  call add(rpl,printf("genvar %s;",a:var))
  call add(rpl,printf("for (%s = 0; %s < %s; %s = %s + 1)",a:var,a:var,a:thld,a:var,a:var))
  call add(rpl,repeat(' ',s:align_tab_indent)."begin : XXX_LOOP")
  call add(rpl,"")
  call add(rpl,repeat(' ',s:align_tab_indent)."end")
  call add(rpl,"endgenerate")
  return rpl
endfunction
function Decgenif(var,thld)
  let rpl = []
  call add(rpl,"generate")
  call add(rpl,printf("if (%s < %s) begin : XXX_BRCH",a:var,a:thld))
  call add(rpl,"")
  call add(rpl,"end")
  call add(rpl,"else begin : YYY_BRCH")
  call add(rpl,"")
  call add(rpl,"end")
  call add(rpl,"endgenerate")
  return rpl
endfunction
function Decgendef(var)
  let rpl = []
  let tmp = printf("`ifdef %s",toupper(a:var))
  let line = tmp.repeat(' ',(s:align_equal_mark-len(tmp))).s:def_mark
  call add(rpl,line)
  call add(rpl,"")
  let line = '`else'.repeat(' ',(s:align_equal_mark-5)).s:def_mark
  call add(rpl,line)
  call add(rpl,"")
  let line = '`endif'.repeat(' ',(s:align_equal_mark-6)).s:def_mark
  call add(rpl,line)
  return rpl
endfunction

function RevIntf() range
  for i in range(a:firstline,a:lastline)
    let line = getline(i)
    if line =~ 'output'
      let line = substitute(line,'output','input ','')
    elseif line =~ 'input '
      let line = substitute(line,'input ','output','')
    endif
    call setline(i,line)
  endfor
endfunction

command -nargs=0 -range=% Rio :<line1>,<line2>call RevIntf()



" }}}
" Move wire {{{
  let bgn_main = search(s:template_main_bgn,'n')
  let end_main = search(s:template_main_end,'n')
  let bgn_declare = search(s:template_declare,'n')

function Wirecollet(mode,bgn,end)
  let pat0_wc = '^\s*\(wire\|reg\)'
  let pat1_wc = '^\s*\(`ifdef\|`ifndef\|`elsif\|`else\|`endif\)'
  let wc_buf = []
  let bgn_main = a:bgn
  let end_main = a:end
  for i in range(bgn_main,end_main)
    let line = getline(i)
    if (line =~ pat0_wc && a:mode == 1)
      call add(wc_buf,[i,line])
      let line = substitute(line,'.*','','')
      call setline(i,line)
    elseif line =~ pat1_wc
      call add(wc_buf,[i,line])
      let line = substitute(line,s:def_mark_srch,'','')
      call setline(i,line)
    endif
  endfor
  return wc_buf
endfunction

function MoveWire()
  let bgn_main = search(s:template_main_bgn,'n')
  let end_main = search(s:template_main_end,'n')
  let bgn_declare = search(s:template_declare,'n')

  let inst_buf = Wirecollet(0,bgn_declare,bgn_main)
  let main_buf = Wirecollet(1,bgn_main,end_main)
  let mv_ptr = bgn_declare + 1

  if inst_buf == []
    call add(inst_buf,[mv_ptr,""])
  endif

  for i in range(len(main_buf))
   let tmpline = main_buf[0][1]
   let tmpinst = inst_buf[0][1]
   let tmpid   = inst_buf[0][0]
   if tmpline =~ '^\s*\(reg\|wire\)'
     call append(mv_ptr,tmpline)
     let mv_ptr = mv_ptr + 1
   elseif tmpline =~ '^\s*\(`ifdef\|`ifndef\|`elsif\|`else\|`endif\)'
     if tmpline =~ s:def_mark_srch
       let tmpline = substitute(tmpline,s:def_mark_srch,'','')
       call append(mv_ptr,tmpline)
       let mv_ptr = mv_ptr + 1
     elseif tmpline == tmpinst
       call remove(inst_buf,0)
       let mv_ptr = tmpid
     endif
   endif
   call remove(main_buf,0)
  endfor

endfunction
command -nargs=* Mreg :call MoveWire(<f-args>)

" }}}
" MISC {{{
function IncDec(mode) range
  let bgn_lid = line("'<")
  let end_lid = line("'>")
  let bgn_cid = col("'<")
  let end_cid = col("'>")
  if bgn_lid > end_lid
    let end_lid = bgn_lid
    let bgn_lid = end_lid
  endif
  if bgn_cid > end_cid
    let end_cid = bgn_cid
    let bgn_cid = end_cid
  endif

  let sub_pat = strpart(getline(bgn_lid),bgn_cid-1,(end_cid-bgn_cid+1))
  let len_lid = end_lid - bgn_lid + 1

  for i in range(len_lid)
    let curline = getline(i+bgn_lid)
    if a:mode == 0
      let rpl =  sub_pat + i
    else
      let rpl =  sub_pat - i
    endif
    let pre_pat = strpart(curline,0,bgn_cid-1)
    let pst_pat = strpart(curline,end_cid)
    let rpl = pre_pat.rpl.pst_pat
    call setline(i+bgn_lid,rpl)
  endfor
endfunction

command -nargs=* -range=% Acc :call IncDec(0)
command -nargs=* -range=% Dec :call IncDec(1)

" }}}
