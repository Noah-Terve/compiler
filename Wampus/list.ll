; ModuleID = 'list.c'
source_filename = "list.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx14.0.0"

%struct.node = type { ptr, ptr }

@__func__._list_insert = private unnamed_addr constant [13 x i8] c"_list_insert\00", align 1
@.str = private unnamed_addr constant [7 x i8] c"list.c\00", align 1
@.str.1 = private unnamed_addr constant [27 x i8] c"(idx >= 0) && (idx <= len)\00", align 1
@.str.2 = private unnamed_addr constant [9 x i8] c"new_node\00", align 1
@.str.3 = private unnamed_addr constant [4 x i8] c"[]\0A\00", align 1
@.str.4 = private unnamed_addr constant [3 x i8] c"[ \00", align 1
@.str.5 = private unnamed_addr constant [4 x i8] c"%d \00", align 1
@.str.6 = private unnamed_addr constant [3 x i8] c"]\0A\00", align 1

; Function Attrs: noinline nounwind optnone ssp uwtable
define zeroext i1 @_list_empty(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = icmp eq ptr %3, null
  br i1 %4, label %9, label %5

5:                                                ; preds = %1
  %6 = load ptr, ptr %2, align 8
  %7 = load ptr, ptr %6, align 8
  %8 = icmp eq ptr %7, null
  br label %9

9:                                                ; preds = %5, %1
  %10 = phi i1 [ true, %1 ], [ %8, %5 ]
  ret i1 %10
}

; Function Attrs: noinline nounwind optnone ssp uwtable
define void @_list_insert(ptr noundef %0, i32 noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca i32, align 4
  %11 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store ptr %2, ptr %6, align 8
  %12 = load ptr, ptr %4, align 8
  %13 = call i32 @_list_len(ptr noundef %12)
  store i32 %13, ptr %7, align 4
  %14 = load i32, ptr %5, align 4
  %15 = icmp uge i32 %14, 0
  br i1 %15, label %16, label %20

16:                                               ; preds = %3
  %17 = load i32, ptr %5, align 4
  %18 = load i32, ptr %7, align 4
  %19 = icmp ule i32 %17, %18
  br label %20

20:                                               ; preds = %16, %3
  %21 = phi i1 [ false, %3 ], [ %19, %16 ]
  %22 = xor i1 %21, true
  %23 = zext i1 %22 to i32
  %24 = sext i32 %23 to i64
  %25 = icmp ne i64 %24, 0
  br i1 %25, label %26, label %28

26:                                               ; preds = %20
  call void @__assert_rtn(ptr noundef @__func__._list_insert, ptr noundef @.str, i32 noundef 20, ptr noundef @.str.1) #4
  unreachable

27:                                               ; No predecessors!
  br label %29

28:                                               ; preds = %20
  br label %29

29:                                               ; preds = %28, %27
  %30 = load ptr, ptr %4, align 8
  %31 = load ptr, ptr %30, align 8
  store ptr %31, ptr %8, align 8
  store ptr null, ptr %9, align 8
  store i32 0, ptr %10, align 4
  br label %32

32:                                               ; preds = %41, %29
  %33 = load i32, ptr %10, align 4
  %34 = load i32, ptr %5, align 4
  %35 = icmp ult i32 %33, %34
  br i1 %35, label %36, label %44

36:                                               ; preds = %32
  %37 = load ptr, ptr %8, align 8
  store ptr %37, ptr %9, align 8
  %38 = load ptr, ptr %8, align 8
  %39 = getelementptr inbounds %struct.node, ptr %38, i32 0, i32 1
  %40 = load ptr, ptr %39, align 8
  store ptr %40, ptr %8, align 8
  br label %41

41:                                               ; preds = %36
  %42 = load i32, ptr %10, align 4
  %43 = add i32 %42, 1
  store i32 %43, ptr %10, align 4
  br label %32, !llvm.loop !6

44:                                               ; preds = %32
  %45 = call ptr @malloc(i64 noundef 16) #5
  store ptr %45, ptr %11, align 8
  %46 = load ptr, ptr %11, align 8
  %47 = icmp ne ptr %46, null
  %48 = xor i1 %47, true
  %49 = zext i1 %48 to i32
  %50 = sext i32 %49 to i64
  %51 = icmp ne i64 %50, 0
  br i1 %51, label %52, label %54

52:                                               ; preds = %44
  call void @__assert_rtn(ptr noundef @__func__._list_insert, ptr noundef @.str, i32 noundef 34, ptr noundef @.str.2) #4
  unreachable

53:                                               ; No predecessors!
  br label %55

54:                                               ; preds = %44
  br label %55

55:                                               ; preds = %54, %53
  %56 = load ptr, ptr %6, align 8
  %57 = load ptr, ptr %11, align 8
  %58 = getelementptr inbounds %struct.node, ptr %57, i32 0, i32 0
  store ptr %56, ptr %58, align 8
  %59 = load ptr, ptr %8, align 8
  %60 = load ptr, ptr %11, align 8
  %61 = getelementptr inbounds %struct.node, ptr %60, i32 0, i32 1
  store ptr %59, ptr %61, align 8
  %62 = load ptr, ptr %9, align 8
  %63 = icmp eq ptr %62, null
  br i1 %63, label %64, label %67

64:                                               ; preds = %55
  %65 = load ptr, ptr %11, align 8
  %66 = load ptr, ptr %4, align 8
  store ptr %65, ptr %66, align 8
  br label %71

67:                                               ; preds = %55
  %68 = load ptr, ptr %11, align 8
  %69 = load ptr, ptr %9, align 8
  %70 = getelementptr inbounds %struct.node, ptr %69, i32 0, i32 1
  store ptr %68, ptr %70, align 8
  br label %71

71:                                               ; preds = %67, %64
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable
define i32 @_list_len(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  %6 = load ptr, ptr %3, align 8
  %7 = call zeroext i1 @_list_empty(ptr noundef %6)
  br i1 %7, label %8, label %9

8:                                                ; preds = %1
  store i32 0, ptr %2, align 4
  br label %24

9:                                                ; preds = %1
  store i32 0, ptr %4, align 4
  %10 = load ptr, ptr %3, align 8
  %11 = load ptr, ptr %10, align 8
  store ptr %11, ptr %5, align 8
  br label %12

12:                                               ; preds = %18, %9
  %13 = load ptr, ptr %5, align 8
  %14 = icmp ne ptr %13, null
  br i1 %14, label %15, label %22

15:                                               ; preds = %12
  %16 = load i32, ptr %4, align 4
  %17 = add i32 %16, 1
  store i32 %17, ptr %4, align 4
  br label %18

18:                                               ; preds = %15
  %19 = load ptr, ptr %5, align 8
  %20 = getelementptr inbounds %struct.node, ptr %19, i32 0, i32 1
  %21 = load ptr, ptr %20, align 8
  store ptr %21, ptr %5, align 8
  br label %12, !llvm.loop !8

22:                                               ; preds = %12
  %23 = load i32, ptr %4, align 4
  store i32 %23, ptr %2, align 4
  br label %24

24:                                               ; preds = %22, %8
  %25 = load i32, ptr %2, align 4
  ret i32 %25
}

; Function Attrs: cold noreturn
declare void @__assert_rtn(ptr noundef, ptr noundef, i32 noundef, ptr noundef) #1

; Function Attrs: allocsize(0)
declare ptr @malloc(i64 noundef) #2

; Function Attrs: noinline nounwind optnone ssp uwtable
define void @_list_remove(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %8 = load ptr, ptr %3, align 8
  %9 = call zeroext i1 @_list_empty(ptr noundef %8)
  br i1 %9, label %10, label %11

10:                                               ; preds = %2
  br label %51

11:                                               ; preds = %2
  %12 = load ptr, ptr %3, align 8
  %13 = load ptr, ptr %12, align 8
  store ptr %13, ptr %5, align 8
  store ptr null, ptr %6, align 8
  store i32 0, ptr %7, align 4
  br label %14

14:                                               ; preds = %28, %11
  %15 = load i32, ptr %7, align 4
  %16 = load i32, ptr %4, align 4
  %17 = icmp ult i32 %15, %16
  br i1 %17, label %18, label %21

18:                                               ; preds = %14
  %19 = load ptr, ptr %5, align 8
  %20 = icmp ne ptr %19, null
  br label %21

21:                                               ; preds = %18, %14
  %22 = phi i1 [ false, %14 ], [ %20, %18 ]
  br i1 %22, label %23, label %31

23:                                               ; preds = %21
  %24 = load ptr, ptr %5, align 8
  store ptr %24, ptr %6, align 8
  %25 = load ptr, ptr %5, align 8
  %26 = getelementptr inbounds %struct.node, ptr %25, i32 0, i32 1
  %27 = load ptr, ptr %26, align 8
  store ptr %27, ptr %5, align 8
  br label %28

28:                                               ; preds = %23
  %29 = load i32, ptr %7, align 4
  %30 = add i32 %29, 1
  store i32 %30, ptr %7, align 4
  br label %14, !llvm.loop !9

31:                                               ; preds = %21
  %32 = load ptr, ptr %5, align 8
  %33 = icmp eq ptr %32, null
  br i1 %33, label %34, label %35

34:                                               ; preds = %31
  br label %51

35:                                               ; preds = %31
  %36 = load ptr, ptr %6, align 8
  %37 = icmp eq ptr %36, null
  br i1 %37, label %38, label %43

38:                                               ; preds = %35
  %39 = load ptr, ptr %5, align 8
  %40 = getelementptr inbounds %struct.node, ptr %39, i32 0, i32 1
  %41 = load ptr, ptr %40, align 8
  %42 = load ptr, ptr %3, align 8
  store ptr %41, ptr %42, align 8
  br label %49

43:                                               ; preds = %35
  %44 = load ptr, ptr %5, align 8
  %45 = getelementptr inbounds %struct.node, ptr %44, i32 0, i32 1
  %46 = load ptr, ptr %45, align 8
  %47 = load ptr, ptr %6, align 8
  %48 = getelementptr inbounds %struct.node, ptr %47, i32 0, i32 1
  store ptr %46, ptr %48, align 8
  br label %49

49:                                               ; preds = %43, %38
  %50 = load ptr, ptr %5, align 8
  call void @free(ptr noundef %50)
  br label %51

51:                                               ; preds = %49, %34, %10
  ret void
}

declare void @free(ptr noundef) #3

; Function Attrs: noinline nounwind optnone ssp uwtable
define ptr @_list_at(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  %8 = load ptr, ptr %4, align 8
  %9 = call zeroext i1 @_list_empty(ptr noundef %8)
  br i1 %9, label %10, label %11

10:                                               ; preds = %2
  store ptr null, ptr %3, align 8
  br label %36

11:                                               ; preds = %2
  %12 = load ptr, ptr %4, align 8
  %13 = load ptr, ptr %12, align 8
  store ptr %13, ptr %6, align 8
  store i32 0, ptr %7, align 4
  br label %14

14:                                               ; preds = %29, %11
  %15 = load i32, ptr %7, align 4
  %16 = load i32, ptr %5, align 4
  %17 = icmp ult i32 %15, %16
  br i1 %17, label %18, label %32

18:                                               ; preds = %14
  %19 = load i32, ptr %5, align 4
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %21, label %25

21:                                               ; preds = %18
  %22 = load ptr, ptr %6, align 8
  %23 = getelementptr inbounds %struct.node, ptr %22, i32 0, i32 0
  %24 = load ptr, ptr %23, align 8
  store ptr %24, ptr %3, align 8
  br label %36

25:                                               ; preds = %18
  %26 = load ptr, ptr %6, align 8
  %27 = getelementptr inbounds %struct.node, ptr %26, i32 0, i32 1
  %28 = load ptr, ptr %27, align 8
  store ptr %28, ptr %6, align 8
  br label %29

29:                                               ; preds = %25
  %30 = load i32, ptr %7, align 4
  %31 = add i32 %30, 1
  store i32 %31, ptr %7, align 4
  br label %14, !llvm.loop !10

32:                                               ; preds = %14
  %33 = load ptr, ptr %6, align 8
  %34 = getelementptr inbounds %struct.node, ptr %33, i32 0, i32 0
  %35 = load ptr, ptr %34, align 8
  store ptr %35, ptr %3, align 8
  br label %36

36:                                               ; preds = %32, %21, %10
  %37 = load ptr, ptr %3, align 8
  ret ptr %37
}

; Function Attrs: noinline nounwind optnone ssp uwtable
define void @_list_int_print(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %7 = load ptr, ptr %2, align 8
  %8 = icmp ne ptr %7, null
  br i1 %8, label %9, label %13

9:                                                ; preds = %1
  %10 = load ptr, ptr %2, align 8
  %11 = load ptr, ptr %10, align 8
  %12 = icmp ne ptr %11, null
  br i1 %12, label %15, label %13

13:                                               ; preds = %9, %1
  %14 = call i32 (ptr, ...) @printf(ptr noundef @.str.3)
  br label %39

15:                                               ; preds = %9
  %16 = load ptr, ptr %2, align 8
  %17 = load ptr, ptr %16, align 8
  store ptr %17, ptr %3, align 8
  store i32 0, ptr %4, align 4
  %18 = load ptr, ptr %2, align 8
  %19 = call i32 @_list_len(ptr noundef %18)
  store i32 %19, ptr %5, align 4
  %20 = call i32 (ptr, ...) @printf(ptr noundef @.str.4)
  br label %21

21:                                               ; preds = %25, %15
  %22 = load i32, ptr %4, align 4
  %23 = load i32, ptr %5, align 4
  %24 = icmp slt i32 %22, %23
  br i1 %24, label %25, label %37

25:                                               ; preds = %21
  %26 = load ptr, ptr %2, align 8
  %27 = load i32, ptr %4, align 4
  %28 = call ptr @_list_at(ptr noundef %26, i32 noundef %27)
  store ptr %28, ptr %6, align 8
  %29 = load ptr, ptr %6, align 8
  %30 = load i32, ptr %29, align 4
  %31 = call i32 (ptr, ...) @printf(ptr noundef @.str.5, i32 noundef %30)
  %32 = load ptr, ptr %3, align 8
  %33 = getelementptr inbounds %struct.node, ptr %32, i32 0, i32 1
  %34 = load ptr, ptr %33, align 8
  store ptr %34, ptr %3, align 8
  %35 = load i32, ptr %4, align 4
  %36 = add nsw i32 %35, 1
  store i32 %36, ptr %4, align 4
  br label %21, !llvm.loop !11

37:                                               ; preds = %21
  %38 = call i32 (ptr, ...) @printf(ptr noundef @.str.6)
  br label %39

39:                                               ; preds = %37, %13
  ret void
}

declare i32 @printf(ptr noundef, ...) #3

attributes #0 = { noinline nounwind optnone ssp uwtable "darwin-stkchk-strong-link" "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "probe-stack"="___chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { cold noreturn "darwin-stkchk-strong-link" "disable-tail-calls"="true" "frame-pointer"="all" "no-trapping-math"="true" "probe-stack"="___chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { allocsize(0) "darwin-stkchk-strong-link" "frame-pointer"="all" "no-trapping-math"="true" "probe-stack"="___chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "darwin-stkchk-strong-link" "frame-pointer"="all" "no-trapping-math"="true" "probe-stack"="___chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { cold noreturn }
attributes #5 = { allocsize(0) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 14, i32 0]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Apple clang version 15.0.0 (clang-1500.0.40.1)"}
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}
!9 = distinct !{!9, !7}
!10 = distinct !{!10, !7}
!11 = distinct !{!11, !7}
