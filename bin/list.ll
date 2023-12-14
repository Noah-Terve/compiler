; ModuleID = 'list.c'
source_filename = "list.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

%struct.node = type { i8*, %struct.node* }

@__func__.list_insert = private unnamed_addr constant [12 x i8] c"list_insert\00", align 1
@.str = private unnamed_addr constant [7 x i8] c"list.c\00", align 1
@.str.1 = private unnamed_addr constant [27 x i8] c"(idx >= 0) && (idx <= len)\00", align 1
@.str.2 = private unnamed_addr constant [9 x i8] c"new_node\00", align 1
@__func__.list_at = private unnamed_addr constant [8 x i8] c"list_at\00", align 1
@.str.3 = private unnamed_addr constant [14 x i8] c"head && *head\00", align 1
@.str.4 = private unnamed_addr constant [4 x i8] c"[]\0A\00", align 1
@.str.5 = private unnamed_addr constant [3 x i8] c"[ \00", align 1
@.str.6 = private unnamed_addr constant [4 x i8] c"%d \00", align 1
@.str.7 = private unnamed_addr constant [3 x i8] c"]\0A\00", align 1
@__func__.list_replace = private unnamed_addr constant [13 x i8] c"list_replace\00", align 1
@.str.8 = private unnamed_addr constant [30 x i8] c"(index >= 0) && (index < len)\00", align 1

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define zeroext i1 @list_empty(%struct.node** noundef %0) #0 {
  %2 = alloca %struct.node**, align 8
  store %struct.node** %0, %struct.node*** %2, align 8
  %3 = load %struct.node**, %struct.node*** %2, align 8
  %4 = icmp eq %struct.node** %3, null
  br i1 %4, label %9, label %5

5:                                                ; preds = %1
  %6 = load %struct.node**, %struct.node*** %2, align 8
  %7 = load %struct.node*, %struct.node** %6, align 8
  %8 = icmp eq %struct.node* %7, null
  br label %9

9:                                                ; preds = %5, %1
  %10 = phi i1 [ true, %1 ], [ %8, %5 ]
  ret i1 %10
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define %struct.node** @list_insert(%struct.node** noundef %0, i32 noundef %1, i8* noundef %2) #0 {
  %4 = alloca %struct.node**, align 8
  %5 = alloca i32, align 4
  %6 = alloca i8*, align 8
  %7 = alloca i32, align 4
  %8 = alloca %struct.node*, align 8
  %9 = alloca %struct.node*, align 8
  %10 = alloca i32, align 4
  %11 = alloca %struct.node*, align 8
  store %struct.node** %0, %struct.node*** %4, align 8
  store i32 %1, i32* %5, align 4
  store i8* %2, i8** %6, align 8
  %12 = load %struct.node**, %struct.node*** %4, align 8
  %13 = call i32 @list_length(%struct.node** noundef %12)
  store i32 %13, i32* %7, align 4
  %14 = load i32, i32* %5, align 4
  %15 = icmp uge i32 %14, 0
  br i1 %15, label %16, label %20

16:                                               ; preds = %3
  %17 = load i32, i32* %5, align 4
  %18 = load i32, i32* %7, align 4
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
  call void @__assert_rtn(i8* noundef getelementptr inbounds ([12 x i8], [12 x i8]* @__func__.list_insert, i64 0, i64 0), i8* noundef getelementptr inbounds ([7 x i8], [7 x i8]* @.str, i64 0, i64 0), i32 noundef 19, i8* noundef getelementptr inbounds ([27 x i8], [27 x i8]* @.str.1, i64 0, i64 0)) #4
  unreachable

27:                                               ; No predecessors!
  br label %29

28:                                               ; preds = %20
  br label %29

29:                                               ; preds = %28, %27
  %30 = load %struct.node**, %struct.node*** %4, align 8
  %31 = load %struct.node*, %struct.node** %30, align 8
  store %struct.node* %31, %struct.node** %8, align 8
  store %struct.node* null, %struct.node** %9, align 8
  store i32 0, i32* %10, align 4
  br label %32

32:                                               ; preds = %41, %29
  %33 = load i32, i32* %10, align 4
  %34 = load i32, i32* %5, align 4
  %35 = icmp ult i32 %33, %34
  br i1 %35, label %36, label %44

36:                                               ; preds = %32
  %37 = load %struct.node*, %struct.node** %8, align 8
  store %struct.node* %37, %struct.node** %9, align 8
  %38 = load %struct.node*, %struct.node** %8, align 8
  %39 = getelementptr inbounds %struct.node, %struct.node* %38, i32 0, i32 1
  %40 = load %struct.node*, %struct.node** %39, align 8
  store %struct.node* %40, %struct.node** %8, align 8
  br label %41

41:                                               ; preds = %36
  %42 = load i32, i32* %10, align 4
  %43 = add i32 %42, 1
  store i32 %43, i32* %10, align 4
  br label %32, !llvm.loop !10

44:                                               ; preds = %32
  %45 = call i8* @malloc(i64 noundef 16) #5
  %46 = bitcast i8* %45 to %struct.node*
  store %struct.node* %46, %struct.node** %11, align 8
  %47 = load %struct.node*, %struct.node** %11, align 8
  %48 = icmp ne %struct.node* %47, null
  %49 = xor i1 %48, true
  %50 = zext i1 %49 to i32
  %51 = sext i32 %50 to i64
  %52 = icmp ne i64 %51, 0
  br i1 %52, label %53, label %55

53:                                               ; preds = %44
  call void @__assert_rtn(i8* noundef getelementptr inbounds ([12 x i8], [12 x i8]* @__func__.list_insert, i64 0, i64 0), i8* noundef getelementptr inbounds ([7 x i8], [7 x i8]* @.str, i64 0, i64 0), i32 noundef 33, i8* noundef getelementptr inbounds ([9 x i8], [9 x i8]* @.str.2, i64 0, i64 0)) #4
  unreachable

54:                                               ; No predecessors!
  br label %56

55:                                               ; preds = %44
  br label %56

56:                                               ; preds = %55, %54
  %57 = load i8*, i8** %6, align 8
  %58 = load %struct.node*, %struct.node** %11, align 8
  %59 = getelementptr inbounds %struct.node, %struct.node* %58, i32 0, i32 0
  store i8* %57, i8** %59, align 8
  %60 = load %struct.node*, %struct.node** %8, align 8
  %61 = load %struct.node*, %struct.node** %11, align 8
  %62 = getelementptr inbounds %struct.node, %struct.node* %61, i32 0, i32 1
  store %struct.node* %60, %struct.node** %62, align 8
  %63 = load %struct.node*, %struct.node** %9, align 8
  %64 = icmp eq %struct.node* %63, null
  br i1 %64, label %65, label %68

65:                                               ; preds = %56
  %66 = load %struct.node*, %struct.node** %11, align 8
  %67 = load %struct.node**, %struct.node*** %4, align 8
  store %struct.node* %66, %struct.node** %67, align 8
  br label %72

68:                                               ; preds = %56
  %69 = load %struct.node*, %struct.node** %11, align 8
  %70 = load %struct.node*, %struct.node** %9, align 8
  %71 = getelementptr inbounds %struct.node, %struct.node* %70, i32 0, i32 1
  store %struct.node* %69, %struct.node** %71, align 8
  br label %72

72:                                               ; preds = %68, %65
  %73 = load %struct.node**, %struct.node*** %4, align 8
  ret %struct.node** %73
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @list_length(%struct.node** noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca %struct.node**, align 8
  %4 = alloca i32, align 4
  %5 = alloca %struct.node*, align 8
  store %struct.node** %0, %struct.node*** %3, align 8
  %6 = load %struct.node**, %struct.node*** %3, align 8
  %7 = call zeroext i1 @list_empty(%struct.node** noundef %6)
  br i1 %7, label %8, label %9

8:                                                ; preds = %1
  store i32 0, i32* %2, align 4
  br label %24

9:                                                ; preds = %1
  store i32 0, i32* %4, align 4
  %10 = load %struct.node**, %struct.node*** %3, align 8
  %11 = load %struct.node*, %struct.node** %10, align 8
  store %struct.node* %11, %struct.node** %5, align 8
  br label %12

12:                                               ; preds = %18, %9
  %13 = load %struct.node*, %struct.node** %5, align 8
  %14 = icmp ne %struct.node* %13, null
  br i1 %14, label %15, label %22

15:                                               ; preds = %12
  %16 = load i32, i32* %4, align 4
  %17 = add i32 %16, 1
  store i32 %17, i32* %4, align 4
  br label %18

18:                                               ; preds = %15
  %19 = load %struct.node*, %struct.node** %5, align 8
  %20 = getelementptr inbounds %struct.node, %struct.node* %19, i32 0, i32 1
  %21 = load %struct.node*, %struct.node** %20, align 8
  store %struct.node* %21, %struct.node** %5, align 8
  br label %12, !llvm.loop !12

22:                                               ; preds = %12
  %23 = load i32, i32* %4, align 4
  store i32 %23, i32* %2, align 4
  br label %24

24:                                               ; preds = %22, %8
  %25 = load i32, i32* %2, align 4
  ret i32 %25
}

; Function Attrs: cold noreturn
declare void @__assert_rtn(i8* noundef, i8* noundef, i32 noundef, i8* noundef) #1

; Function Attrs: allocsize(0)
declare i8* @malloc(i64 noundef) #2

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define %struct.node** @list_remove(%struct.node** noundef %0, i32 noundef %1) #0 {
  %3 = alloca %struct.node**, align 8
  %4 = alloca %struct.node**, align 8
  %5 = alloca i32, align 4
  %6 = alloca %struct.node*, align 8
  %7 = alloca %struct.node*, align 8
  %8 = alloca i32, align 4
  store %struct.node** %0, %struct.node*** %4, align 8
  store i32 %1, i32* %5, align 4
  %9 = load %struct.node**, %struct.node*** %4, align 8
  %10 = call zeroext i1 @list_empty(%struct.node** noundef %9)
  br i1 %10, label %11, label %13

11:                                               ; preds = %2
  %12 = load %struct.node**, %struct.node*** %4, align 8
  store %struct.node** %12, %struct.node*** %3, align 8
  br label %55

13:                                               ; preds = %2
  %14 = load %struct.node**, %struct.node*** %4, align 8
  %15 = load %struct.node*, %struct.node** %14, align 8
  store %struct.node* %15, %struct.node** %6, align 8
  store %struct.node* null, %struct.node** %7, align 8
  store i32 0, i32* %8, align 4
  br label %16

16:                                               ; preds = %30, %13
  %17 = load i32, i32* %8, align 4
  %18 = load i32, i32* %5, align 4
  %19 = icmp ult i32 %17, %18
  br i1 %19, label %20, label %23

20:                                               ; preds = %16
  %21 = load %struct.node*, %struct.node** %6, align 8
  %22 = icmp ne %struct.node* %21, null
  br label %23

23:                                               ; preds = %20, %16
  %24 = phi i1 [ false, %16 ], [ %22, %20 ]
  br i1 %24, label %25, label %33

25:                                               ; preds = %23
  %26 = load %struct.node*, %struct.node** %6, align 8
  store %struct.node* %26, %struct.node** %7, align 8
  %27 = load %struct.node*, %struct.node** %6, align 8
  %28 = getelementptr inbounds %struct.node, %struct.node* %27, i32 0, i32 1
  %29 = load %struct.node*, %struct.node** %28, align 8
  store %struct.node* %29, %struct.node** %6, align 8
  br label %30

30:                                               ; preds = %25
  %31 = load i32, i32* %8, align 4
  %32 = add i32 %31, 1
  store i32 %32, i32* %8, align 4
  br label %16, !llvm.loop !13

33:                                               ; preds = %23
  %34 = load %struct.node*, %struct.node** %6, align 8
  %35 = icmp eq %struct.node* %34, null
  br i1 %35, label %36, label %37

36:                                               ; preds = %33
  store %struct.node** null, %struct.node*** %3, align 8
  br label %55

37:                                               ; preds = %33
  %38 = load %struct.node*, %struct.node** %7, align 8
  %39 = icmp eq %struct.node* %38, null
  br i1 %39, label %40, label %45

40:                                               ; preds = %37
  %41 = load %struct.node*, %struct.node** %6, align 8
  %42 = getelementptr inbounds %struct.node, %struct.node* %41, i32 0, i32 1
  %43 = load %struct.node*, %struct.node** %42, align 8
  %44 = load %struct.node**, %struct.node*** %4, align 8
  store %struct.node* %43, %struct.node** %44, align 8
  br label %51

45:                                               ; preds = %37
  %46 = load %struct.node*, %struct.node** %6, align 8
  %47 = getelementptr inbounds %struct.node, %struct.node* %46, i32 0, i32 1
  %48 = load %struct.node*, %struct.node** %47, align 8
  %49 = load %struct.node*, %struct.node** %7, align 8
  %50 = getelementptr inbounds %struct.node, %struct.node* %49, i32 0, i32 1
  store %struct.node* %48, %struct.node** %50, align 8
  br label %51

51:                                               ; preds = %45, %40
  %52 = load %struct.node*, %struct.node** %6, align 8
  %53 = bitcast %struct.node* %52 to i8*
  call void @free(i8* noundef %53)
  %54 = load %struct.node**, %struct.node*** %4, align 8
  store %struct.node** %54, %struct.node*** %3, align 8
  br label %55

55:                                               ; preds = %51, %36, %11
  %56 = load %struct.node**, %struct.node*** %3, align 8
  ret %struct.node** %56
}

declare void @free(i8* noundef) #3

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i8* @list_at(%struct.node** noundef %0, i32 noundef %1) #0 {
  %3 = alloca i8*, align 8
  %4 = alloca %struct.node**, align 8
  %5 = alloca i32, align 4
  %6 = alloca %struct.node*, align 8
  %7 = alloca i32, align 4
  store %struct.node** %0, %struct.node*** %4, align 8
  store i32 %1, i32* %5, align 4
  %8 = load %struct.node**, %struct.node*** %4, align 8
  %9 = icmp ne %struct.node** %8, null
  br i1 %9, label %10, label %14

10:                                               ; preds = %2
  %11 = load %struct.node**, %struct.node*** %4, align 8
  %12 = load %struct.node*, %struct.node** %11, align 8
  %13 = icmp ne %struct.node* %12, null
  br label %14

14:                                               ; preds = %10, %2
  %15 = phi i1 [ false, %2 ], [ %13, %10 ]
  %16 = xor i1 %15, true
  %17 = zext i1 %16 to i32
  %18 = sext i32 %17 to i64
  %19 = icmp ne i64 %18, 0
  br i1 %19, label %20, label %22

20:                                               ; preds = %14
  call void @__assert_rtn(i8* noundef getelementptr inbounds ([8 x i8], [8 x i8]* @__func__.list_at, i64 0, i64 0), i8* noundef getelementptr inbounds ([7 x i8], [7 x i8]* @.str, i64 0, i64 0), i32 noundef 75, i8* noundef getelementptr inbounds ([14 x i8], [14 x i8]* @.str.3, i64 0, i64 0)) #4
  unreachable

21:                                               ; No predecessors!
  br label %23

22:                                               ; preds = %14
  br label %23

23:                                               ; preds = %22, %21
  %24 = load %struct.node**, %struct.node*** %4, align 8
  %25 = load %struct.node*, %struct.node** %24, align 8
  store %struct.node* %25, %struct.node** %6, align 8
  store i32 0, i32* %7, align 4
  br label %26

26:                                               ; preds = %41, %23
  %27 = load i32, i32* %7, align 4
  %28 = load i32, i32* %5, align 4
  %29 = icmp ult i32 %27, %28
  br i1 %29, label %30, label %44

30:                                               ; preds = %26
  %31 = load i32, i32* %5, align 4
  %32 = icmp eq i32 %31, 0
  br i1 %32, label %33, label %37

33:                                               ; preds = %30
  %34 = load %struct.node*, %struct.node** %6, align 8
  %35 = getelementptr inbounds %struct.node, %struct.node* %34, i32 0, i32 0
  %36 = load i8*, i8** %35, align 8
  store i8* %36, i8** %3, align 8
  br label %48

37:                                               ; preds = %30
  %38 = load %struct.node*, %struct.node** %6, align 8
  %39 = getelementptr inbounds %struct.node, %struct.node* %38, i32 0, i32 1
  %40 = load %struct.node*, %struct.node** %39, align 8
  store %struct.node* %40, %struct.node** %6, align 8
  br label %41

41:                                               ; preds = %37
  %42 = load i32, i32* %7, align 4
  %43 = add i32 %42, 1
  store i32 %43, i32* %7, align 4
  br label %26, !llvm.loop !14

44:                                               ; preds = %26
  %45 = load %struct.node*, %struct.node** %6, align 8
  %46 = getelementptr inbounds %struct.node, %struct.node* %45, i32 0, i32 0
  %47 = load i8*, i8** %46, align 8
  store i8* %47, i8** %3, align 8
  br label %48

48:                                               ; preds = %44, %33
  %49 = load i8*, i8** %3, align 8
  ret i8* %49
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @list_int_print(%struct.node** noundef %0) #0 {
  %2 = alloca %struct.node**, align 8
  %3 = alloca %struct.node*, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32*, align 8
  store %struct.node** %0, %struct.node*** %2, align 8
  %7 = load %struct.node**, %struct.node*** %2, align 8
  %8 = icmp ne %struct.node** %7, null
  br i1 %8, label %9, label %13

9:                                                ; preds = %1
  %10 = load %struct.node**, %struct.node*** %2, align 8
  %11 = load %struct.node*, %struct.node** %10, align 8
  %12 = icmp ne %struct.node* %11, null
  br i1 %12, label %15, label %13

13:                                               ; preds = %9, %1
  %14 = call i32 (i8*, ...) @printf(i8* noundef getelementptr inbounds ([4 x i8], [4 x i8]* @.str.4, i64 0, i64 0))
  br label %40

15:                                               ; preds = %9
  %16 = load %struct.node**, %struct.node*** %2, align 8
  %17 = load %struct.node*, %struct.node** %16, align 8
  store %struct.node* %17, %struct.node** %3, align 8
  store i32 0, i32* %4, align 4
  %18 = load %struct.node**, %struct.node*** %2, align 8
  %19 = call i32 @list_length(%struct.node** noundef %18)
  store i32 %19, i32* %5, align 4
  %20 = call i32 (i8*, ...) @printf(i8* noundef getelementptr inbounds ([3 x i8], [3 x i8]* @.str.5, i64 0, i64 0))
  br label %21

21:                                               ; preds = %25, %15
  %22 = load i32, i32* %4, align 4
  %23 = load i32, i32* %5, align 4
  %24 = icmp slt i32 %22, %23
  br i1 %24, label %25, label %38

25:                                               ; preds = %21
  %26 = load %struct.node**, %struct.node*** %2, align 8
  %27 = load i32, i32* %4, align 4
  %28 = call i8* @list_at(%struct.node** noundef %26, i32 noundef %27)
  %29 = bitcast i8* %28 to i32*
  store i32* %29, i32** %6, align 8
  %30 = load i32*, i32** %6, align 8
  %31 = load i32, i32* %30, align 4
  %32 = call i32 (i8*, ...) @printf(i8* noundef getelementptr inbounds ([4 x i8], [4 x i8]* @.str.6, i64 0, i64 0), i32 noundef %31)
  %33 = load %struct.node*, %struct.node** %3, align 8
  %34 = getelementptr inbounds %struct.node, %struct.node* %33, i32 0, i32 1
  %35 = load %struct.node*, %struct.node** %34, align 8
  store %struct.node* %35, %struct.node** %3, align 8
  %36 = load i32, i32* %4, align 4
  %37 = add nsw i32 %36, 1
  store i32 %37, i32* %4, align 4
  br label %21, !llvm.loop !15

38:                                               ; preds = %21
  %39 = call i32 (i8*, ...) @printf(i8* noundef getelementptr inbounds ([3 x i8], [3 x i8]* @.str.7, i64 0, i64 0))
  br label %40

40:                                               ; preds = %38, %13
  ret void
}

declare i32 @printf(i8* noundef, ...) #3

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define %struct.node** @list_replace(%struct.node** noundef %0, i32 noundef %1, i8* noundef %2) #0 {
  %4 = alloca %struct.node**, align 8
  %5 = alloca i32, align 4
  %6 = alloca i8*, align 8
  %7 = alloca i32, align 4
  %8 = alloca %struct.node*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32, align 4
  store %struct.node** %0, %struct.node*** %4, align 8
  store i32 %1, i32* %5, align 4
  store i8* %2, i8** %6, align 8
  %11 = load %struct.node**, %struct.node*** %4, align 8
  %12 = icmp ne %struct.node** %11, null
  br i1 %12, label %13, label %17

13:                                               ; preds = %3
  %14 = load %struct.node**, %struct.node*** %4, align 8
  %15 = load %struct.node*, %struct.node** %14, align 8
  %16 = icmp ne %struct.node* %15, null
  br label %17

17:                                               ; preds = %13, %3
  %18 = phi i1 [ false, %3 ], [ %16, %13 ]
  %19 = xor i1 %18, true
  %20 = zext i1 %19 to i32
  %21 = sext i32 %20 to i64
  %22 = icmp ne i64 %21, 0
  br i1 %22, label %23, label %25

23:                                               ; preds = %17
  call void @__assert_rtn(i8* noundef getelementptr inbounds ([13 x i8], [13 x i8]* @__func__.list_replace, i64 0, i64 0), i8* noundef getelementptr inbounds ([7 x i8], [7 x i8]* @.str, i64 0, i64 0), i32 noundef 129, i8* noundef getelementptr inbounds ([14 x i8], [14 x i8]* @.str.3, i64 0, i64 0)) #4
  unreachable

24:                                               ; No predecessors!
  br label %26

25:                                               ; preds = %17
  br label %26

26:                                               ; preds = %25, %24
  %27 = load %struct.node**, %struct.node*** %4, align 8
  %28 = call i32 @list_length(%struct.node** noundef %27)
  store i32 %28, i32* %7, align 4
  %29 = load i32, i32* %5, align 4
  %30 = icmp uge i32 %29, 0
  br i1 %30, label %31, label %35

31:                                               ; preds = %26
  %32 = load i32, i32* %5, align 4
  %33 = load i32, i32* %7, align 4
  %34 = icmp ult i32 %32, %33
  br label %35

35:                                               ; preds = %31, %26
  %36 = phi i1 [ false, %26 ], [ %34, %31 ]
  %37 = xor i1 %36, true
  %38 = zext i1 %37 to i32
  %39 = sext i32 %38 to i64
  %40 = icmp ne i64 %39, 0
  br i1 %40, label %41, label %43

41:                                               ; preds = %35
  call void @__assert_rtn(i8* noundef getelementptr inbounds ([13 x i8], [13 x i8]* @__func__.list_replace, i64 0, i64 0), i8* noundef getelementptr inbounds ([7 x i8], [7 x i8]* @.str, i64 0, i64 0), i32 noundef 130, i8* noundef getelementptr inbounds ([30 x i8], [30 x i8]* @.str.8, i64 0, i64 0)) #4
  unreachable

42:                                               ; No predecessors!
  br label %44

43:                                               ; preds = %35
  br label %44

44:                                               ; preds = %43, %42
  %45 = load %struct.node**, %struct.node*** %4, align 8
  %46 = load %struct.node*, %struct.node** %45, align 8
  store %struct.node* %46, %struct.node** %8, align 8
  store i8* null, i8** %9, align 8
  store i32 0, i32* %10, align 4
  br label %47

47:                                               ; preds = %55, %44
  %48 = load i32, i32* %10, align 4
  %49 = load i32, i32* %5, align 4
  %50 = icmp ult i32 %48, %49
  br i1 %50, label %51, label %58

51:                                               ; preds = %47
  %52 = load %struct.node*, %struct.node** %8, align 8
  %53 = getelementptr inbounds %struct.node, %struct.node* %52, i32 0, i32 1
  %54 = load %struct.node*, %struct.node** %53, align 8
  store %struct.node* %54, %struct.node** %8, align 8
  br label %55

55:                                               ; preds = %51
  %56 = load i32, i32* %10, align 4
  %57 = add i32 %56, 1
  store i32 %57, i32* %10, align 4
  br label %47, !llvm.loop !16

58:                                               ; preds = %47
  %59 = load %struct.node*, %struct.node** %8, align 8
  %60 = getelementptr inbounds %struct.node, %struct.node* %59, i32 0, i32 0
  %61 = load i8*, i8** %60, align 8
  store i8* %61, i8** %9, align 8
  %62 = load i8*, i8** %6, align 8
  %63 = load %struct.node*, %struct.node** %8, align 8
  %64 = getelementptr inbounds %struct.node, %struct.node* %63, i32 0, i32 0
  store i8* %62, i8** %64, align 8
  %65 = load i8*, i8** %9, align 8
  %66 = icmp ne i8* %65, null
  br i1 %66, label %67, label %69

67:                                               ; preds = %58
  %68 = load i8*, i8** %9, align 8
  call void @free(i8* noundef %68)
  br label %69

69:                                               ; preds = %67, %58
  %70 = load %struct.node**, %struct.node*** %4, align 8
  ret %struct.node** %70
}

attributes #0 = { noinline nounwind optnone ssp uwtable(sync) "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { cold noreturn "disable-tail-calls"="true" "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #2 = { allocsize(0) "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #3 = { "frame-pointer"="non-leaf" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #4 = { cold noreturn }
attributes #5 = { allocsize(0) }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 13, i32 3]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"branch-target-enforcement", i32 0}
!3 = !{i32 8, !"sign-return-address", i32 0}
!4 = !{i32 8, !"sign-return-address-all", i32 0}
!5 = !{i32 8, !"sign-return-address-with-bkey", i32 0}
!6 = !{i32 7, !"PIC Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 1}
!8 = !{i32 7, !"frame-pointer", i32 1}
!9 = !{!"Apple clang version 14.0.3 (clang-1403.0.22.14.1)"}
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.mustprogress"}
!12 = distinct !{!12, !11}
!13 = distinct !{!13, !11}
!14 = distinct !{!14, !11}
!15 = distinct !{!15, !11}
!16 = distinct !{!16, !11}
