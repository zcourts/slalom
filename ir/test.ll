; For test output in main
%TestName = type [13 x i8]
@.NULLC = private unnamed_addr constant i8 0
declare i32 @putchar(i32) nounwind
declare i32 @puts(i8* nocapture) nounwind

define void @assertEqIndex(%Index, %Index, %TestName* %name) {
  %equal = icmp eq %Index %0, %1
  call void @assertCond(i1 %equal, %TestName* %name)
  ret void
}

define void @assertEqFunction(%Function*, %Function*, %TestName* %name) {
  %equal = icmp eq %Function* %0, %1
  call void @assertCond(i1 %equal, %TestName* %name)
  ret void
}

define void @assertEqQueueNode(%QueueNode*, %QueueNode*, %TestName* %name) {
  %equal = icmp eq %QueueNode* %0, %1
  call void @assertCond(i1 %equal, %TestName* %name)
  ret void
}

define void @assertEqBody(%Body*, %Body, %TestName* %name) {
  %b = load %Body* %0
  %equal = icmp eq %Body %b, %1
  call void @assertCond(i1 %equal, %TestName* %name)
  ret void
}

define void @assertCond(i1 %cond, %TestName* %name) {
entry:
  br i1 %cond, label %testPassed, label %testFailed
testPassed:
  call i32 @putchar(i32 46) ; Prints a period
  ret void
testFailed:
  %namePtr = getelementptr %TestName* %name, i64 0, i64 0
  call i32 @puts(i8* @.NULLC)
  call i32 @puts(i8* %namePtr)
  ret void
}

define i1 @main() {
entry:
  call void @testLast()
  call void @testCreateEmptyQueue()
  call void @testEnqueue()
  call void @testDequeue()
  call void @testNullCut()
  call void @testHappyCut()
  call void @testPaste()
  call void @testQCopy()

  call void @testCreateICombinator()
  call void @testCreateKCombinator()
  call void @testCreateSCombinator()
;  call void @testFCopy()
;  call void @testEvaluate()
;  call void @testApply()
;  call void @testSubstitute()

  call i32 @puts(i8* @.NULLC)
  ret i1 0
}

@.sBodyDequeue = private unnamed_addr constant %TestName c"SBodyDequeue\00"
@.sArity2      = private unnamed_addr constant %TestName c"S Arity 2   \00"
@.sArgsEmpty   = private unnamed_addr constant %TestName c"S Args Empty\00"
define void @testCreateSCombinator() {
  %s = call %Function* @createSCombinator()

  ; Assert body is @substitute
  %body = call %Body* @getBodyPointer(%Function* %s)
  call void @assertEqBody(%Body* %body, %Body @substitute, %TestName* @.sBodyDequeue)

  ; Assert arity 3
  %arity = call %Index @getArity(%Function* %s)
  call void @assertEqIndex(%Index %arity, %Index 3, %TestName* @.sArity2)

  ; Assert arguments queue is empty
  %arguments = call %Queue* @getArguments(%Function* %s)
  %isEmpty = call i1 @isEmpty(%Queue* %arguments)
  call void @assertCond(i1 %isEmpty, %TestName* @.sArgsEmpty)

  call void @fDestroy(%Function* %s)
  ret void
}

@.kBodyDequeue = private unnamed_addr constant %TestName c"KBodyDequeue\00"
@.kArity2      = private unnamed_addr constant %TestName c"K Arity 2   \00"
@.kArgsEmpty   = private unnamed_addr constant %TestName c"K Args Empty\00"
define void @testCreateKCombinator() {
  %k = call %Function* @createKCombinator()

  ; Assert body is dequeue
  %body = call %Body* @getBodyPointer(%Function* %k)
  call void @assertEqBody(%Body* %body, %Body @dequeue, %TestName* @.kBodyDequeue)

  ; Assert arity 2
  %arity = call %Index @getArity(%Function* %k)
  call void @assertEqIndex(%Index %arity, %Index 2, %TestName* @.kArity2)

  ; Assert arguments queue is empty
  %arguments = call %Queue* @getArguments(%Function* %k)
  %isEmpty = call i1 @isEmpty(%Queue* %arguments)
  call void @assertCond(i1 %isEmpty, %TestName* @.kArgsEmpty)

  call void @fDestroy(%Function* %k)
  ret void
}

@.copyF1IsntF1 = private unnamed_addr constant %TestName c"CopyF1IsntF1\00"
@.deepCopyN1   = private unnamed_addr constant %TestName c"Deep Copy F1\00"
@.copyF2IsntF2 = private unnamed_addr constant %TestName c"CopyF2IsntF2\00"
@.deepCopyN2   = private unnamed_addr constant %TestName c"Deep Copy F2\00"
define void @testQCopy() {
  %original = call %Queue* @createEmptyQueue()
  %f1 = call %Function* @createICombinator()
  call void @setArity(%Function* %f1, %Index 3)
  %f2 = call %Function* @createICombinator()
  call void @setArity(%Function* %f2, %Index 7)
  call void @enqueue(%Queue* %original, %Function* %f1)
  call void @enqueue(%Queue* %original, %Function* %f2)

  ; Copy the original
  %copy = call %Queue* @qCopy(%Queue* %original)
  %cNode1 = call %QueueNode* @getHead(%Queue* %copy)
  %cNode2 = call %QueueNode* @getTail(%Queue* %copy)

  %oNode1 = call %QueueNode* @getHead(%Queue* %original)
  %oNode2 = call %QueueNode* @getTail(%Queue* %original)

  ; Assert that cNode1 and oNode1 are deep copies
  %copyF1 = call %Function* @getData(%QueueNode* %cNode1)
  %headsNotEqual = icmp ne %Function* %f1, %copyF1
  call void @assertCond(i1 %headsNotEqual, %TestName* @.copyF1IsntF1)
  %o1Arity = call %Index @getArity(%Function* %f1)
  %c1Arity = call %Index @getArity(%Function* %copyF1)
  call void @assertEqIndex(%Index %o1Arity, %Index %c1Arity, %TestName* @.deepCopyN1)

  ; Assert that cNode2 and oNode2 are deep copies
  %copyF2 = call %Function* @getData(%QueueNode* %cNode2)
  %tailsNotEqual = icmp ne %Function* %f2, %copyF2
  call void @assertCond(i1 %tailsNotEqual, %TestName* @.copyF2IsntF2)
  %o2Arity = call %Index @getArity(%Function* %f2)
  %c2Arity = call %Index @getArity(%Function* %copyF2)
  call void @assertEqIndex(%Index %o2Arity, %Index %c2Arity, %TestName* @.deepCopyN2)

  call void @qDestroy(%Queue* %original)
  call void @qDestroy(%Queue* %copy)
  ret void
}

@.pasteLength4 = private unnamed_addr constant %TestName c"PasteLength4\00"
@.pasteTailF4  = private unnamed_addr constant %TestName c"PasteTailF4 \00"
@.pasteN3IsF3  = private unnamed_addr constant %TestName c"PasteN3IsF3 \00"
define void @testPaste() {
  %main = call %Queue* @createEmptyQueue()
  %toPaste = call %Queue* @createEmptyQueue()
  %f1 = call %Function* @createICombinator()
  %f2 = call %Function* @createICombinator()
  %f3 = call %Function* @createICombinator()
  %f4 = call %Function* @createICombinator()
  call void @enqueue(%Queue* %main, %Function* %f1)
  call void @enqueue(%Queue* %main, %Function* %f2)
  call void @enqueue(%Queue* %toPaste, %Function* %f3)
  call void @enqueue(%Queue* %toPaste, %Function* %f4)

  ; Paste toPaste into main
  call void @paste(%Queue* %main, %Queue* %toPaste)

  ; Assert main has length 2
  %pasteLength = call %Index @getLength(%Queue* %main)
  call void @assertEqIndex(%Index %pasteLength, %Index 4, %TestName* @.pasteLength4)

  ; Assert that tail of main is f4
  %pasteTail = call %QueueNode* @getTail(%Queue* %main)
  %pasteTailData = call %Function* @getData(%QueueNode* %pasteTail)
  call void @assertEqFunction(%Function* %pasteTailData, %Function* %f4, %TestName* @.pasteTailF4)

  ; Assert that 3rd node in main contains f3
  %pasteHead = call %QueueNode* @getHead(%Queue* %main)
  %node3 = call %QueueNode* @getLink(%QueueNode* %pasteHead, %Index 3)
  %node3Data = call %Function* @getData(%QueueNode* %node3)
  call void @assertEqFunction(%Function* %node3Data, %Function* %f3, %TestName* @.pasteN3IsF3)

  call void @qDestroy(%Queue* %main)
  ret void
}

@.cutLength2   = private unnamed_addr constant %TestName c"Cut Length 2\00"
@.cut2HeadF1   = private unnamed_addr constant %TestName c"Cut2 Head F1\00"
@.cut2TailF2   = private unnamed_addr constant %TestName c"Cut2 Tail F2\00"
@.cut2TailLast = private unnamed_addr constant %TestName c"Cut2TailLast\00"
@.qHeadF3      = private unnamed_addr constant %TestName c"Q Head F3   \00"
@.qLength1     = private unnamed_addr constant %TestName c"Q Length 1  \00"
define void @testHappyCut() {
  %q = call %Queue* @createEmptyQueue()
  %f1 = call %Function* @createICombinator()
  %f2 = call %Function* @createICombinator()
  %f3 = call %Function* @createICombinator()
  call void @enqueue(%Queue* %q, %Function* %f1)
  call void @enqueue(%Queue* %q, %Function* %f2)
  call void @enqueue(%Queue* %q, %Function* %f3)

  ; Cut 2 from q
  %cut2 = call %Queue* @cut(%Queue* %q, %Index 2)

  ; Assert that cut2 has length 2
  %cut2Length = call %Index @getLength(%Queue* %cut2)
  call void @assertEqIndex(%Index %cut2Length, %Index 2, %TestName* @.cutLength2)

  ; Assert that head of cut2 contains f1
  %cut2N1 = call %QueueNode* @getHead(%Queue* %cut2)
  %n1Data = call %Function* @getData(%QueueNode* %cut2N1)
  call void @assertEqFunction(%Function* %n1Data, %Function* %f1, %TestName* @.cut2HeadF1)

  ; Assert that tail of cut2 contains f2
  %cut2N2 = call %QueueNode* @getTail(%Queue* %cut2)
  %n2Data = call %Function* @getData(%QueueNode* %cut2N2)
  call void @assertEqFunction(%Function* %n2Data, %Function* %f2, %TestName* @.cut2TailF2)

  ; Assert that tail.next is LAST
  %n2Next = call %QueueNode* @getNext(%QueueNode* %cut2N2)
  call void @assertEqQueueNode(%QueueNode* %n2Next, %QueueNode* @.LAST, %TestName* @.cut2TailLast)

  ; Assert that head of q contains f3
  %qHead = call %QueueNode* @getHead(%Queue* %q)
  %qHeadData = call %Function* @getData(%QueueNode* %qHead)
  call void @assertEqFunction(%Function* %qHeadData, %Function* %f3, %TestName* @.qHeadF3)

  ; Assert that q has length 1
  %qLength = call %Index @getLength(%Queue* %q)
  call void @assertEqIndex(%Index %qLength, %Index 1, %TestName* @.qLength1)

  call void @qDestroy(%Queue* %cut2)
  call void @qDestroy(%Queue* %q)
  ret void
}

@.cut0IsEmpty  = private unnamed_addr constant %TestName c"Cut0IsEmpty \00"
@.cut0IsNotQ   = private unnamed_addr constant %TestName c"Cut0IsNotQ  \00"
define void @testNullCut() {
  %q = call %Queue* @createEmptyQueue()

  ; Cut 0 from q
  %cut0 = call %Queue* @cut(%Queue* %q, %Index 0)

  ; Assert that cut0 is empty
  %cut0IsEmpty = call i1 @isEmpty(%Queue* %cut0)
  call void @assertCond(i1 %cut0IsEmpty, %TestName* @.cut0IsEmpty)

  ; Assert that cut0 and q are different
  %cut0IsNotQ = icmp ne %Queue* %cut0, %q
  call void @assertCond(i1 %cut0IsNotQ, %TestName* @.cut0IsNotQ) 

  call void @qDestroy(%Queue* %cut0)
  call void @qDestroy(%Queue* %q)
  ret void
}

@.dq1IsF1      = private unnamed_addr constant %TestName c"DQ1 Is F1   \00"
@.qSmaller1    = private unnamed_addr constant %TestName c"Q Smaller 1 \00"
@.headIsN2     = private unnamed_addr constant %TestName c"Head Is N2  \00"
@.qSmaller0    = private unnamed_addr constant %TestName c"Q Smaller 0 \00"
@.dq2IsF2      = private unnamed_addr constant %TestName c"DQ2 Is F2   \00"
@.headIsLast   = private unnamed_addr constant %TestName c"Head Is Last\00"
@.qNoSmaller   = private unnamed_addr constant %TestName c"Q No Smaller\00"
@.dq3IsNull    = private unnamed_addr constant %TestName c"DQ3 Is Null \00"
@.headNotNull  = private unnamed_addr constant %TestName c"HeadNotNull \00"
define void @testDequeue() {
  ; create a queue with some functions
  %q = call %Queue* @createEmptyQueue()
  %f1 = call %Function* @createICombinator()
  %f2 = call %Function* @createICombinator()
  call void @enqueue(%Queue* %q, %Function* %f1)
  %node1 = call %QueueNode* @getTail(%Queue* %q)
  call void @enqueue(%Queue* %q, %Function* %f2)
  %node2 = call %QueueNode* @getTail(%Queue* %q)

  ; Dequeue a function
  %dq1 = call %Function* @dequeue(%Queue* %q)

  ; Assert that q length is 1
  %length = call %Index @getLength(%Queue* %q)
  call void @assertEqIndex(%Index %length, %Index 1, %TestName* @.qSmaller1)

  ; Assert that dq1 is f1
  call void @assertEqFunction(%Function* %dq1, %Function* %f1, %TestName* @.dq1IsF1)

  ; Assert that q head is node2
  %head = call %QueueNode* @getHead(%Queue* %q)
  call void @assertEqQueueNode(%QueueNode* %head, %QueueNode* %node2, %TestName* @.headIsN2)

  ; Dequeue another function
  %dq2 = call %Function* @dequeue(%Queue* %q)

  ; Assert that q is empty
  %isEmpty = call i1 @isEmpty(%Queue* %q)
  call void @assertCond(i1 %isEmpty, %TestName* @.qSmaller0)

  ; Assert that dq2 is f2
  call void @assertEqFunction(%Function* %dq2, %Function* %f2, %TestName* @.dq2IsF2)

  ; Assert that q head is LAST
  %head2 = call %QueueNode* @getHead(%Queue* %q)
  call void @assertEqQueueNode(%QueueNode* %head2, %QueueNode* @.LAST, %TestName* @.headIsLast)

  ; Dequeue another function
  %dq3 = call %Function* @dequeue(%Queue* %q)

  ; Assert that q length is still 0
  %isStillEmpty = call i1 @isEmpty(%Queue* %q)
  call void @assertCond(i1 %isStillEmpty, %TestName* @.qNoSmaller)

  ; Assert that dq3 is null
  call void @assertEqFunction(%Function* %dq3, %Function* null, %TestName* @.dq3IsNull)
  
  ; Assert that q head is LAST
  %head3 = call %QueueNode* @getHead(%Queue* %q)
  call void @assertEqQueueNode(%QueueNode* %head3, %QueueNode* @.LAST, %TestName* @.headNotNull)

  call void @fDestroy(%Function* %dq1)
  call void @fDestroy(%Function* %dq2)
  call void @qDestroy(%Queue* %q)
  ret void
}

@.qBigger1     = private unnamed_addr constant %TestName c"Q Bigger 1  \00"
@.headIsN1     = private unnamed_addr constant %TestName c"Head Is N1  \00"
@.n1HasF1      = private unnamed_addr constant %TestName c"N1 Has F1   \00"
@.n1PtToLast   = private unnamed_addr constant %TestName c"N1PtToLast  \00"
@.qBigger2     = private unnamed_addr constant %TestName c"Q Bigger 2  \00"
@.n2HasF2      = private unnamed_addr constant %TestName c"N2 Has F2   \00"
@.headNoChange = private unnamed_addr constant %TestName c"HeadNoChange\00"
@.n1PtToN2     = private unnamed_addr constant %TestName c"N1 Pt To N2 \00"
@.n1NotPtToN3  = private unnamed_addr constant %TestName c"N1NotPtToN3 \00"
@.n2PtToN3     = private unnamed_addr constant %TestName c"N2 Pt To N3 \00"
define void @testEnqueue() {
  %q = call %Queue* @createEmptyQueue()
  
  ; Enqueue a function
  %f1 = call %Function* @createICombinator()
  call void @enqueue(%Queue* %q, %Function* %f1)
  %node1 = call %QueueNode* @getTail(%Queue* %q)

  ; Assert that q length is 1
  %length1 = call %Index @getLength(%Queue* %q)
  call void @assertEqIndex(%Index %length1, %Index 1, %TestName* @.qBigger1)

  ; Assert that node1 contains f1
  %node1Data = call %Function* @getData(%QueueNode* %node1)
  call void @assertEqFunction(%Function* %node1Data, %Function* %f1, %TestName* @.n1HasF1)

  ; Assert that node1 points to LAST
  %node1Next = call %QueueNode* @getNext(%QueueNode* %node1)
  call void @assertEqQueueNode(%QueueNode* %node1Next, %QueueNode* @.LAST, %TestName* @.n1PtToLast)

  ; Assert that q head is node1
  %head = call %QueueNode* @getHead(%Queue* %q)
  call void @assertEqQueueNode(%QueueNode* %node1, %QueueNode* %head, %TestName* @.headIsN1)

  ; Enqueue another function
  %f2 = call %Function* @createICombinator()
  call void @enqueue(%Queue* %q, %Function* %f2)
  %node2 = call %QueueNode* @getTail(%Queue* %q)

  ; Assert that q length is 2
  %length2 = call %Index @getLength(%Queue* %q)
  call void @assertEqIndex(%Index %length2, %Index 2, %TestName* @.qBigger2)

  ; Assert that node2 contains f2
  %node2Data = call %Function* @getData(%QueueNode* %node2)
  call void @assertEqFunction(%Function* %node2Data, %Function* %f2, %TestName* @.n2HasF2)

  ; Assert that q head is still node1
  %head2 = call %QueueNode* @getHead(%Queue* %q)
  call void @assertEqQueueNode(%QueueNode* %head2, %QueueNode* %node1, %TestName* @.headNoChange)

  ; Assert that node1 points to node2
  %node1Next2 = call %QueueNode* @getNext(%QueueNode* %node1)
  call void @assertEqQueueNode(%QueueNode* %node1Next2, %QueueNode* %node2, %TestName* @.n1PtToN2)

  ; Enqueue another function
  %f3 = call %Function* @createICombinator()
  call void @enqueue(%Queue* %q, %Function* %f3)
  %node3 = call %QueueNode* @getTail(%Queue* %q)

  ; Assert that node1 still points to node2
  %node1Next3 = call %QueueNode* @getNext(%QueueNode* %node1)
  call void @assertEqQueueNode(%QueueNode* %node1Next3, %QueueNode* %node2, %TestName* @.n1NotPtToN3)

  ; Assert that node2 points to node3
  %node2Next = call %QueueNode* @getNext(%QueueNode* %node2)
  call void @assertEqQueueNode(%QueueNode* %node2Next, %QueueNode* %node3, %TestName* @.n2PtToN3)

  call void @qDestroy(%Queue* %q)
  ret void
}

@.iArity1 = private unnamed_addr constant %TestName c"I Arity 1   \00"
@.iArgsEmpty = private unnamed_addr constant %TestName c"I Args Empty\00"
@.iBodyDequeue = private unnamed_addr constant %TestName c"IBodyDequeue\00"
define void @testCreateICombinator() {
  %i = call %Function* @createICombinator()

  ; Assert that body is @dequeue
  %body_p = call %Body* @getBodyPointer(%Function* %i)
  call void @assertEqBody(%Body* %body_p, %Body @dequeue, %TestName* @.iBodyDequeue)

  ; Assert that arity is 1
  %arity = call %Index @getArity(%Function* %i)
  call void @assertEqIndex(%Index %arity, %Index 1, %TestName* @.iArity1)

  ; Assert that arguments is an empty queue
  %arguments = call %Queue* @getArguments(%Function* %i)
  %isEmpty = call i1 @isEmpty(%Queue* %arguments)
  call void @assertCond(i1 %isEmpty, %TestName* @.iArgsEmpty)

  call void @fDestroy(%Function* %i)
  ret void
}

@.emptyLength0 = private unnamed_addr constant %TestName c"EmptyLength0\00"
@.emptyHead = private unnamed_addr constant %TestName c"EmptyHead   \00"
@.emptyTail = private unnamed_addr constant %TestName c"EmptyTail   \00"
define void @testCreateEmptyQueue() {
  %q = call %Queue* @createEmptyQueue()

  ; Assert that length of q is 0
  %q_len = call %Index @getLength(%Queue* %q)
  call void @assertEqIndex(%Index %q_len, %Index 0, %TestName* @.emptyLength0)

  ; Assert that head node of q is LAST
  %q_head = call %QueueNode* @getHead(%Queue* %q)
  call void @assertEqQueueNode(%QueueNode* %q_head, %QueueNode* @.LAST, %TestName* @.emptyHead)

  ; Assert that tail node of q is LAST
  %q_tail = call %QueueNode* @getTail(%Queue* %q)
  call void @assertEqQueueNode(%QueueNode* %q_tail, %QueueNode* @.LAST, %TestName* @.emptyTail)

  call void @qDestroy(%Queue* %q)
  ret void
}

@.lastDataNull = private unnamed_addr constant %TestName c"LastDataNull\00"
@.lastNextNull = private unnamed_addr constant %TestName c"LastNextNull\00"
define void @testLast() {
  ; Assert that @.LAST.argument is null
  %last_data = call %Function* @getData(%QueueNode* @.LAST)
  call void @assertEqFunction(%Function* %last_data, %Function* null, %TestName* @.lastDataNull)

  ; Assert that @.LAST.next is null
  %last_next = call %QueueNode* @getNext(%QueueNode* @.LAST)
  call void @assertEqQueueNode(%QueueNode* %last_next, %QueueNode* null, %TestName* @.lastNextNull)

  ret void
}