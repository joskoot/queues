#lang scribble/manual

@;====================================================================================================

@(require
   scribble/core
   scribble/eval   
   racket
   "queues.rkt"
   "srcribble-utensils.rkt"
   (for-label "queues.rkt" racket)
   (for-template "queues.rkt" racket)
   (for-syntax racket))

@title[#:version ""]{Queues}
@author{Jacob J. A. Koot}
@;@(defmodule "queues.rkt" #:packages ())
@(defmodule queues/queues #:packages ())

@section{Introduction}

A queue is a first in first out memory.@(lb)
Procedure @nbr[make-queue] renders a queue.@(lb)
Procedure @nbr[queue-put!] mutates a queue by adding an element.@(lb)
Procedure @nbr[queue-get!] returns the oldest element of a queue@(lb)
and mutates the queue by removing this element.

@Interaction[
 (define q (make-queue))
 (for ((e (in-list '(a b c)))) (queue-put! q e))
 (for/list ((k (in-range (queue-length q)))) (queue-get! q))
 (queue-empty? q)]

More procedures are available. See section @seclink["procedures"]{Procedures}.@(lb)
Queues have @nbrl[prop:sequence]{sequence-property}. See procedure @nbr[in-queue].

@section{Implementation}

A queue as described in the present document is represented by a
@seclink["structures" #:doc '(lib "scribblings/reference/reference.scrbl")]{structure} containing a
@seclink["mpairs" #:doc '(lib "scribblings/reference/reference.scrbl")]{mutable list}
plus two other fields: the length of the mutable list
and a pointer to the last element.
In fact the pointer is the last pair of the mutable list.
If the queue is empty the mutable list and the pointer are null.
Using a simplified description, the two elementary operations are as follows.
@nb{The first} element is easily retrieved by taking the @nbr[mcar] of the mutable list
and removing it by replacing the list by its @nbr[mcdr].
@nb{An element} is added at the end by appending it to the pointer and updating the pointer
such as to point to the new element.
Both operations take constant time,
independently of the length of the queue and the size of the data.

No indices are required to enter or retrieve elements,
but as the elements have time order,
indexed access is posible too.
The elements are indexed by natural numbers in the same way the elements of a list or vector
are indexed for procedure @nbr[list-ref] or @nbr[vector-ref].
The oldest element has index zero.
Removing an element from a queue effectively decreases the indices of all
newer elements by one. Indexed access takes time proportional to the index.

@Interaction[
 (queue-print-content 'yes)
 (define q (list->queue '(a b c d)))
 (queue-ref q 1)
 q
 (queue-remove! q 1)
 q
 (code:line (queue-ref q 1) (code:comment #,(red "Not the same as before!")))]

@section[#:tag "procedures"]{Procedures}

Module @hyperlink["../../queues.rkt"]{queues.rkt} provides procedures only,
no syntaxes or other types of objects.
@nb{Where applicable}, the description of a procedure includes a statement about the time it takes.
A procedure whose name ends with an exclamation mark mutates a queue.
@nb{An exclamation} mark not necessarily implies that the procedure returns @(Void).@(lb)
The procedures are described in order of their names.

@defproc[(in-queue (‹queue› queue?)) sequence?]{
 Queues have this procedure as @nbrl[prop:sequence]{sequence property}.
 Same as @nbr[(queue->list ‹queue›)],@(lb)
 but in a for-clause faster and without conversion of the @nbr[‹queue›] to a list.

 @Interaction[
 (define a (make-queue 1 2 3))
 (define b (make-queue 'a 'b))
 (queue-print-content #t)
 (list a b)
 (for* ((a a) (b b)) (writeln (list a b)))
 (code:comment "Works, but the following is faster:")
 (for* ((a (in-queue a)) (b (in-queue b))) (writeln (list a b)))
 (code:comment #,(list (nbr in-queue) " does no mutation."))
 (list a b)]

 @red{Caveat}: Results can be surprising when an imperative queue procedure is applied to the
 @nbr[‹queue›] in other for-clauses or in the body of a @nbr[for] loop.
 The following would write symbol @green{@tt{a}} followed by an infinite number of
 symbol @green{@tt{b}} if the thread were not killed.

 @Interaction[
 (define q (make-queue 'a))
 (define p (open-output-string))
 (define thrd
   (thread
     (λ ()
       (for ((e (in-queue! q)))
         (queue-put! q 'b)
         (write e p)))))
 (sleep 1)
 (kill-thread thrd)
 (flush-output p)
 (string-length (get-output-string p))]}

@defproc[(in-queue! (‹queue› queue?)) (or/c list? sequence?)]{
 Same as @nbr[in-queue], but removes each visited element from the @nbr[‹queue›].@(lb)
 Can be used in for-clauses only.

 @Interaction[
 (define q (make-queue 1 2 3 4 5))
 (for/list ((k (in-range 3)) (x (in-queue! q))) x)
 (code:comment #,(list (nbr in-queue!) " mutates the queue."))
 (queue-print-content 'yes)                  
 q]

 @Interaction[
 (in-queue! (make-queue))]

 @red{Caveat}: Results can be surprising when an imperative queue procedure is applied to the
 @nbr[‹queue›] in other for-clauses or in the body of a @nbr[for] loop.
 In each cycle of the for loop the current element is removed from the @nbr[‹queue›].
 @nb{Use procedure} @nbr[in-queue] for non destructive traversal through the queue.
 In the following example variable @tt{i} assumes value 0 only,
 because after the first iteration through the queue, the latter will be empty.

 @Interaction[
 (queue-print-content #t)
 (define q (make-queue 'a 'b 'c))
 (for* ((i (in-range 100)) (e (in-queue! q)))
   (writeln (list i e (queue->list q))))]

 The following example yields odd results because it applies @nbr[queue-get!]
 in a for-clause:

 @Interaction[
 (define q (make-queue 'a 'b 'c 'd))
 (for/list ((e (in-queue! q)) #:do ((writeln (queue-get! q)))) e)]

 Compare @nbr[in-queue] with @nbr[in-queue!]:

 @Interaction[
 (define q (make-queue 0 1 2 3 4 5 6 7 8 9))
 (code:comment " ")
 (for/list ((a (in-queue q)) (b (in-queue q))) (list a b))
 (queue-length q)
 (code:comment " ")
 (code:comment #,(black "Whereas with " @nbr[in-queue!] ":"))
 (code:comment " ")
 (for/list ((a (in-queue! q)) (b (in-queue! q))) (list a b))
 (queue-length q)]}

@defproc[(list->queue (‹lst› list?)) queue?]{
 Same as @nbr[(apply make-queue ‹lst›)].
 Time proportional to the length of the @nbr[‹lst›].}

@defproc[(make-queue (‹obj› any/c) ...) queue?]{
 Makes a queue containing the @nbr[‹obj›]s in order
 with the left-most one as the first element
 and the right-most one the last element.
 If no @nbr[‹obj›] is given, the returned queue is empty.@(lb)
 Time proportional to the number of @nbr[‹obj›]s
 because the list of @nbr[‹obj›]s is transformed to a mutable list.}

@defproc[(queue->list (‹queue› queue?)) list?]{
 Returns a list of the elements of the @nbr[‹queue›] in order from first to last.
 Time proportional to the @nbrl[queue-length]{length} of the @nbr[‹queue›]
 because it implies conversion of a mutable list to an immutable one.
 @ignore{See procedure @nbr[queue->mlist] too.}

 @Interaction[
 (queue->list (make-queue 1 2 3 4 5))]}

@defproc[(queue-clear! (‹queue› queue?)) void?]{
 Empties the @nbr[‹queue›]. Fixed time.}

@defproc[(queue-copy (‹queue› queue?)) queue?]{
 Returns a copy of the @nbr[‹queue›].
 Mutation of the copy does not affect the original and reversely.
 Time proportional to the length of the @nbr[‹queue›].

 @Interaction[
 (define q (make-queue 'a 'b 'c 'd))
 (define c (queue-copy q))
 (queue-remove! q 2)
 (queue-remove! c 3)
 (queue-print-content #t)
 q
 c
 ]}

@defproc[(queue-empty? (‹queue› queue?)) boolean?]{Constant time.}

@defproc[(queue-filter (‹queue› queue?) (‹pred› (-> any/c any/c))) queue?]{
 Like @nbr[filter], but applying to queues.
 Mutation of the returned queue does not affect the original and reversely.
 If the @nbr[‹pred›] takes constant time,
 then procedure @nbr[queue-filter] takes time proportional to the length of the @nbr[‹queue›].}

@defproc*[(((queue-get! (‹queue› queue?)) any/c)
           ((queue-get! (‹queue› queue?)
              (‹escape› (or/c (not/c procedure?) (procedure-arity-includes/c 0)))) any/c))]{
 Returns the first element of the @nbr[‹queue›] and removes it.
 Constant time.@(lb)
 If the @nbr[‹queue›] is empty, the result depends on @nbr[‹escape›].@(lb)
 @(hspace 2)If it is not present, an exception is raised.@(lb)
 @(hspace 2)If it is a procedure whose arity includes 0,
 this procedure is called at tail position.@(lb)
 @(hspace 2)If it is a not a procedure, @nbr[‹escape›] is returned.@(lb)
 @(hspace 2)Else an exception is raised.

 @Interaction*[
 (queue-get! (make-queue 'a))
 (define empty-queue (make-queue))
 (queue-get! empty-queue #f)
 (queue-get! empty-queue (λ () (displayln "empty queue")))
 (queue-get! empty-queue)]

 An escape procedure not including arity 0 yields an exception,@(lb)
 but the arity is checked only if the queue is empty:

 @Interaction*[
 (queue-get! (make-queue 'a) (λ (x) x))
 (queue-get! empty-queue (λ (x) x))]

 A removed element becomes garbage collectable if no longer accessible otherwise:

 @Interaction[
 (define b (make-weak-box (list 'aap)))
 (define q (make-queue (weak-box-value b)))
 (queue-get! q)
 (collect-garbage)
 (weak-box-value b)]}

@defproc[(queue-length (‹queue› queue?)) natural?]{
 Returns the number of elements currently in the @nbr[‹queue›]. Constant time.}

@defproc[(queue-map (‹queue› queue?) (‹function› (-> any/c any/c))) queue?]{
 Like @nbr[map], but applying to queues.
 Mutation of the returned queue does not affect the original and reversely.
 If the @nbr[‹function›] takes constant time,
 then procedure @nbr[queue-map] takes time proportional to the length of the @nbr[‹queue›].}

@defproc*[(((queue-peek (‹queue› queue?)) any/c)
           ((queue-peek (‹queue› queue?)
              (‹escape› (or/c (not/c procedure?) (procedure-arity-includes/c 0)))) any/c))]{
 Returns the first element of the @nbr[‹queue›] without removing it.
 Constant time.@(lb)
 If the @nbr[‹queue›] is empty, the result depends on @nbr[‹escape›].@(lb)
 @(hspace 2)If it is not present, an exception is raised.@(lb)
 @(hspace 2)If it is a procedure whose arity includes 0,
 this procedure is called at tail position.@(lb)
 @(hspace 2)If it is a not a procedure, @nbr[‹escape›] is returned.@(lb)
 @(hspace 2)Else an exception is raised.}

@defparam*[queue-print-content ‹yes/no› any/c boolean? #:value #f]{
 If @nbr[‹yes/no›] is anything else than @nbr[#f],
 the parameter is set to @nbr[#t].
 Queues are opaque objects, but parameter @nbr[queue-print-content]
 can be used to choose the way a queue is printed.
 If the parameter is false, a queue is printed as
 @inset{@nb{@tt{#<queue:@itt{‹length›>}}}}
 else as
 @inset{@nb{@tt{#<queue:@itt{‹length›}:@(string #\{)@itt{‹element›} ...@(string #\})>}}}

 @Interaction[
 (define q (make-queue 'a 'b 'c))
 (parameterize ((queue-print-content #f)) (writeln q))
 (parameterize ((queue-print-content #t)) (writeln q))]}

@defproc[(queue-put! (‹queue› queue?) (‹obj› any/c)) void?]{
 Adds the @nbr[‹obj›] as the last one in the @nbr[‹queue›].
 Constant time.

 @Interaction[
 (define q (make-queue 'a 'b 'c))
 (queue-put! q 'aap)
 (queue->list q)]}

@defproc[(queue-put!* (‹queue› queue?) (‹obj› any/c) ...) void?]{
 Adds the @nbr[‹obj›]s as the last ones in the @nbr[‹queue›].
 The right-most @nbr[‹obj›] will be the last element.
 Time proportional to the number of @nbr[‹obj›]s.
 The time does not depend on the current @nbrl[queue-length]{length} of the @nbr[‹queue›].

 @Interaction[
 (define q (make-queue))
 (queue-put!* q 'a 'b 'c)
 (queue->list q)]}

@defproc*[(((queue-ref (‹queue› queue?) (‹n› natural?)) any/c)
           ((queue-ref (‹queue› queue?) (‹n› natural?)
              (‹escape› (or/c (not/c procedure?) (procedure-arity-includes/c 0)))) any/c))]{
 Returns the @nbr[‹n›]@superscript{th} element of the @nbr[‹queue›]
 without removing it.
 Time proportional to @nbr[‹n›].@(lb)
 Elements are indexed from 0 up to but not including the length of the queue.@(lb)
 If the @nbr[‹queue›] has less than @nbr[(add1 ‹n›)] elements,
 the result depends on @nbr[‹escape›].@(lb)
 @(hspace 2)If it is not present, an exception is raised.@(lb)
 @(hspace 2)If it is a procedure whose arity includes 0,
 this procedure is called at tail position.@(lb)
 @(hspace 2)If it is a not a procedure, @nbr[‹escape›] is returned.@(lb)
 @(hspace 2)Else an exception is raised.}

@defproc*[(((queue-remove! (‹queue› queue?) (‹n› natural?)) any/c)
           ((queue-remove! (‹queue› queue?) (‹n› natural?)
              (‹escape› (or/c (not/c procedure?) (procedure-arity-includes/c 0)))) any/c))]{
 Like @nbr[queue-ref], but also removes the referenced element from the @nbr[‹queue›].@(lb)
 Time proportional to @nbr[‹n›].}

@defproc[(queue? (‹obj› any/c)) boolean?]{Constant time.}

@ignore{@defproc[(queue->mlist (‹queue› queue?)) mlist?]{
  Returns a mutable list of the elements of the @nbr[‹queue›] in order from first to last.
  Returns the same mutable list (in the sense of @nbr[eq?])
  when applied multiple times to the same @nbr[‹queue›]
  without intervening mutation of this @nbr[‹queue›].
  Constant time. @red{Warning}: the returned mutable list is the same one as stored in the
  @nbr[‹queue›] and mutating it may corrupt the @nbr[‹queue›].
  In particular its pointer to the last element may become useless:

  @Interaction[
 (define q (make-queue 'a 'b 'c 'd))
 (define m (queue->mlist q))
 (set-mcdr! (mcdr m) (mcons 'e '()))
 (writeln (queue->list q))
 (queue-put! q 'x)
 (code:comment "The new element is not properly put into the queue.")
 (queue->list q)]}}

@section{Examples}

@Interaction[
 (define q (make-queue 1 2 3 4))
 (for ((k (in-range 5 10)))
   (define before (queue->list q))
   (queue-put! q k)
   (define get (queue-get! q))
   (define after (queue->list q))
   (printf "~s ~s ~s~n" before get after))]

@Interaction[
 (define q (make-queue))
 (queue-put!* q 0 1 2 3 4 5)
 (printf "~s ~s~n" (queue-peek q) (queue->list q))
 (printf "~s ~s~n" (queue-get! q) (queue->list q))
 (printf "~s ~s~n" (queue-ref q 3) (queue->list q))
 (printf "~s ~s~n" (queue-remove! q 3) (queue->list q))]

@nbr[queue-copy], @nbr[queue-filter] and @nbr[queue-map]
return a copy or partial copy of the @nbr[‹queue›].
Imperative queue procedures do not affect the copy and reversely:

@Interaction[
 (define q (list->queue (build-list 10 values)))
 (define c (queue-copy q))
 (queue-put! q 'aap)
 (queue-get! c)
 (queue->list q)
 (queue->list c)]

A queue can contain other queues as its elements.
It can even contain itself as element,
but this makes no sense:

@(define rec-q-comment
   (list
     @red{Caveat:}
     @black{ procedure }
     @nbr[queue-get!]
     @black{ mutates the queue, which will become empty:}))

@Interaction[
 (define recursive-q (make-queue))
 (queue-put! recursive-q recursive-q)
 (queue-print-content 'yes)
 recursive-q
 (queue-peek recursive-q)
 (eq? recursive-q (queue-peek recursive-q))
 (code:comment #,rec-q-comment)
 (queue-get! recursive-q)]

@section{Test}

Do n @nbrl[queue-put!]{queue-puts} randomly interspersed with @nbrl[queue-get!]{queue-gets}
and check that elements are retrieved in the right order.
Statistics are gathered in mutable variables,
because this simplifies the code substantially.

@Interaction[
 (define n 100)
 (random-seed 0)
 (define q (make-queue))
 (code:comment "Mutable variables for statistics.")
 (code:line (define nput 0)           (code:comment "Count nr of queue-puts."))
 (code:line (define nget 0)           (code:comment "Count nr of queue-gets on non empty queue."))
 (code:line (define nempty 0)         (code:comment "Count nr of times the queue is empty."))
 (code:line (define nremaining 0)     (code:comment "Queue length after all puts have been done."))
 (code:line (define sum-of-lengths 0) (code:comment "Divided by n for the mean queue length."))
 (define max-length 0)
 (code:comment "The test procedure.")
 (define (test element-to-put expected-to-get)
   (define put-cycle? (zero? (random 2)))
   (cond
     ((zero? element-to-put)
      (code:comment "All elements have been put. Get those still in the queue.") 
      (cond
        ((queue-empty? q) 'ok)
        (else
          (set! nremaining (add1 nremaining))
          (unless (= (queue-get! q) expected-to-get)
            (error "test fails"))
          (test 0 (sub1 expected-to-get)))))
     (put-cycle?
       (code:comment "Put cycle.")
       (queue-put! q element-to-put)
       (define n (queue-length q))
       (set! nput (add1 nput))
       (set! max-length (max max-length n))
       (set! sum-of-lengths (+ sum-of-lengths n))
       (test (sub1 element-to-put) expected-to-get))
     (code:comment "Get cycle. Distinct actions for empty and non empty queue.")
     ((queue-empty? q)
      (code:comment "Ignore get cycle on empty queue, but do count it.")
      (set! nempty (add1 nempty))
      (test element-to-put expected-to-get))
     (else
       (code:comment "Get cycle on non empty queue.")
       (unless (= (queue-get! q) expected-to-get)
         (error "test fails"))
       (set! nget (add1 nget))
       (test element-to-put (sub1 expected-to-get)))))
 (code:comment "Do the test.")
 (test n n)
 (cond
   ((= (+ nget nremaining) nput n) 'ok)
   (else (error "test fails")))
 (code:comment "Print statistics.")
 (begin
   (printf "nr of puts                      : ~s~n" nput)
   (printf "nr of gets before last put      : ~s~n" nget)
   (printf "queue length after last put     : ~s~n" nremaining)
   (printf "nr of times the queue was empty : ~s~n" nempty)
   (printf "max  queue length               : ~s~n" max-length)
   (printf "mean queue length               : ~s~n" 
     (exact->inexact (/ sum-of-lengths nput))))]

The mean queue length applies to lengths after a @nbrl[queue-put!]{put} only.@(lb)
The mean does not apply to lengths after a @nbrl[queue-get!]{get} operation.

@larger{@bold{end}}
