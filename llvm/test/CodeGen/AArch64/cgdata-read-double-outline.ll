; This test demonstrates how identical instruction sequences are handled during global outlining.
; Identical sequences that match against the global outlined hash tree are grouped,
; so they share a single outlined function instead of each being outlined separately.

; RUN: split-file %s %t

; First, we generate the cgdata file from a local outline instance present in local-two.ll.
; RUN: llc -mtriple=arm64-apple-darwin -enable-machine-outliner -codegen-data-generate=true -filetype=obj %t/local-two.ll -o %t_write
; RUN: llvm-cgdata --merge %t_write -o %t_cgdata
; RUN: llvm-cgdata --show %t_cgdata | FileCheck %s --check-prefix=SHOW

; SHOW: Outlined hash tree:
; SHOW-NEXT:  Total Node Count: 4
; SHOW-NEXT:  Terminal Node Count: 1
; SHOW-NEXT:  Depth: 3

; Now, we read the cgdata for local-two-another.ll and outline the sequences that
; match against the global outlined hash tree. The two matching sequences are
; identical, so they are grouped and share a single outlined function.

; RUN: llc -mtriple=arm64-apple-darwin -enable-machine-outliner -codegen-data-use-path=%t_cgdata -filetype=obj %t/local-two-another.ll -o %t_read
; RUN: llvm-objdump -d %t_read | FileCheck %s

; Re-run with the outlined hash tree read in place instead of
; fully materialized, and confirm the same outlining is produced.
; RUN: llc -mtriple=arm64-apple-darwin -enable-machine-outliner -codegen-data-use-path=%t_cgdata -indexed-codegen-data-lazy-loading -filetype=obj %t/local-two-another.ll -o %t_read_lazy
; RUN: llvm-objdump -d %t_read_lazy | FileCheck %s

; CHECK: _OUTLINED_FUNCTION_{{.*}}:
; CHECK-NEXT:  mov
; CHECK-NEXT:  mov
; CHECK-NEXT:  b
; CHECK-NOT: _OUTLINED_FUNCTION_{{.*}}:

;--- local-two.ll
declare i32 @g(i32, i32, i32)
define i32 @f1() minsize {
  %1 = call i32 @g(i32 10, i32 1, i32 2);
  ret i32 %1
}
define i32 @f2() minsize {
  %1 = call i32 @g(i32 20, i32 1, i32 2);
  ret i32 %1
}

;--- local-two-another.ll
declare i32 @g(i32, i32, i32)
define i32 @f3() minsize {
  %1 = call i32 @g(i32 30, i32 1, i32 2);
  ret i32 %1
}
define i32 @f4() minsize {
  %1 = call i32 @g(i32 40, i32 1, i32 2);
  ret i32 %1
}
