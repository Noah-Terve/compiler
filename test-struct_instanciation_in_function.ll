; ModuleID = 'Wampus'
source_filename = "Wampus"

%Node = type opaque
%_box.int = type { i32 }

@fmt = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@fmt.1 = private unnamed_addr constant [3 x i8] c"%g\00", align 1
@fmt.2 = private unnamed_addr constant [3 x i8] c"%s\00", align 1
@fmt.3 = private unnamed_addr constant [3 x i8] c"%c\00", align 1
@fmt.4 = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@fmt.5 = private unnamed_addr constant [4 x i8] c"%g\0A\00", align 1
@fmt.6 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@fmt.7 = private unnamed_addr constant [4 x i8] c"%c\0A\00", align 1
@fmt.8 = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@fmt.9 = private unnamed_addr constant [3 x i8] c"%g\00", align 1
@fmt.10 = private unnamed_addr constant [3 x i8] c"%s\00", align 1
@fmt.11 = private unnamed_addr constant [3 x i8] c"%c\00", align 1
@fmt.12 = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@fmt.13 = private unnamed_addr constant [4 x i8] c"%g\0A\00", align 1
@fmt.14 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@fmt.15 = private unnamed_addr constant [4 x i8] c"%c\0A\00", align 1
@fmt.16 = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@fmt.17 = private unnamed_addr constant [3 x i8] c"%g\00", align 1
@fmt.18 = private unnamed_addr constant [3 x i8] c"%s\00", align 1
@fmt.19 = private unnamed_addr constant [3 x i8] c"%c\00", align 1
@fmt.20 = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@fmt.21 = private unnamed_addr constant [4 x i8] c"%g\0A\00", align 1
@fmt.22 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@fmt.23 = private unnamed_addr constant [4 x i8] c"%c\0A\00", align 1

declare i32 @printf(i8*, ...)

declare { i8*, %Node* }** @list_insert({ i8*, %Node* }**, i32, i8*)

declare i32 @list_length({ i8*, %Node* }**)

declare { i8*, %Node* }** @list_remove({ i8*, %Node* }**, i32)

declare { i8*, %Node* }** @list_replace({ i8*, %Node* }**, i32, i8*)

declare i8* @list_at({ i8*, %Node* }**, i32)

declare void @list_int_print({ i8*, %Node* }**)

declare i8* @string_concat(i8*, i8*)

define i32 @list_length_new({ i8*, %Node* }** %0) {
entry:
  %len = alloca i32, align 4
  %curr = alloca { i8*, %Node* }*, align 8
  store i32 0, i32* %len, align 4
  %head = load { i8*, %Node* }*, { i8*, %Node* }** %0, align 8
  store { i8*, %Node* }* %head, { i8*, %Node* }** %curr, align 8
  br label %loop_cond

loop_cond:                                        ; preds = %loop, %entry
  %curr1 = load { i8*, %Node* }*, { i8*, %Node* }** %curr, align 8
  %is_null = icmp eq { i8*, %Node* }* %curr1, null
  br i1 %is_null, label %exit_loop, label %loop

loop:                                             ; preds = %loop_cond
  %curr2 = load { i8*, %Node* }*, { i8*, %Node* }** %curr, align 8
  %next_ptr = getelementptr inbounds { i8*, %Node* }, { i8*, %Node* }* %curr2, i32 0, i32 1
  %len3 = load i32, i32* %len, align 4
  %len4 = add i32 %len3, 1
  store i32 %len4, i32* %len, align 4
  br label %loop_cond

exit_loop:                                        ; preds = %loop_cond
  %len5 = load i32, i32* %len, align 4
  ret i32 %len5
}

define i32 @main() {
entry:
  %intresult = call i32 @"main,"()
  ret i32 0
}

define %_box.int* @"make_new_box,_box.int"(%_box.int* %b) {
entry:
  %b1 = alloca %_box.int*, align 8
  store %_box.int* %b, %_box.int** %b1, align 8
  %empty_struct = alloca %_box.int, align 8
  store %_box.int zeroinitializer, %_box.int* %empty_struct, align 4
  %b0 = alloca %_box.int*, align 8
  store %_box.int* %empty_struct, %_box.int** %b0, align 8
  %b2 = load %_box.int*, %_box.int** %b1, align 8
  store %_box.int* %b2, %_box.int** %b0, align 8
  %b03 = load %_box.int*, %_box.int** %b0, align 8
  %item = getelementptr inbounds %_box.int, %_box.int* %b03, i32 0, i32 0
  store i32 4, i32* %item, align 4
  %b04 = load %_box.int*, %_box.int** %b0, align 8
  ret %_box.int* %b04
}

define i32 @"main,"() {
entry:
  %empty_struct = alloca %_box.int, align 8
  store %_box.int zeroinitializer, %_box.int* %empty_struct, align 4
  %b = alloca %_box.int*, align 8
  store %_box.int* %empty_struct, %_box.int** %b, align 8
  %b1 = load %_box.int*, %_box.int** %b, align 8
  %item = getelementptr inbounds %_box.int, %_box.int* %b1, i32 0, i32 0
  store i32 3, i32* %item, align 4
  %b2 = load %_box.int*, %_box.int** %b, align 8
  %"stru -> _box.intresult" = call %_box.int* @"make_new_box,_box.int"(%_box.int* %b2)
  ret i32 0
}
