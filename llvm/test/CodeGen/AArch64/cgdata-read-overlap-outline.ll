; This test checks global outlining when a sequence matches at overlapping
; positions. Identical sequences across functions share 1 outlined function,
; and overlapping matches within a function are not outlined together (which
; would corrupt the block).

; RUN: split-file %s %t

; Generate cgdata whose only terminal is a run of identical stores: gen_a and
; gen_b share the run but diverge right after it, so only the run is outlined.
; RUN: llc -mtriple=aarch64-linux-gnu -enable-machine-outliner -codegen-data-generate=true -filetype=obj %t/gen.ll -o %t_gen
; RUN: llvm-cgdata --merge %t_gen -o %t_cgdata
; RUN: llvm-cgdata --show %t_cgdata | FileCheck %s --check-prefix=SHOW

; SHOW: Outlined hash tree:
; SHOW-NEXT:  Total Node Count: 9
; SHOW-NEXT:  Terminal Node Count: 1
; SHOW-NEXT:  Depth: 8

; foo and bar hold the exact 8-store sequence; baz holds 9, so the
; sequence matches at offsets 0 and 1, which overlap. All 3 share 1
; outlined function, and baz keeps its 9th store (the overlapping match is
; dropped).
; RUN: llc -mtriple=aarch64-linux-gnu -enable-machine-outliner -codegen-data-use-path=%t_cgdata -filetype=obj %t/use.ll -o %t_use
; RUN: llvm-objdump -d %t_use | FileCheck %s

; Same result with the outlined hash tree read in place.
; RUN: llc -mtriple=aarch64-linux-gnu -enable-machine-outliner -codegen-data-use-path=%t_cgdata -indexed-codegen-data-lazy-loading -filetype=obj %t/use.ll -o %t_use_lazy
; RUN: llvm-objdump -d %t_use_lazy | FileCheck %s

; CHECK-LABEL: <foo>:
; CHECK:         bl{{.*}}<[[OUT:OUTLINED_FUNCTION_[0-9]+]]
; CHECK:         ret
; CHECK-LABEL: <bar>:
; CHECK:         bl{{.*}}<[[OUT]]
; CHECK:         ret
; CHECK-LABEL: <baz>:
; CHECK:         bl{{.*}}<[[OUT]]
; CHECK:         str
; CHECK:         ret
; CHECK:       <[[OUT]]{{.*}}>:
; CHECK-COUNT-8: str
; CHECK-NEXT:    ret
; CHECK-NOT:     OUTLINED_FUNCTION

;--- gen.ll
define void @gen_a(ptr %p) minsize {
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  ret void
}
define void @gen_b(ptr %p, ptr %q) minsize {
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %q
  ret void
}

;--- use.ll
define void @foo(ptr %p) minsize {
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  ret void
}
define void @bar(ptr %p) minsize {
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  ret void
}
define void @baz(ptr %p) minsize {
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  store volatile i32 0, ptr %p
  ret void
}
