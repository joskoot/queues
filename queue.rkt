#lang racket/base

#|====================================================================================================
QUEUES

See file manual.html for documentation.
Make this documentation with file manual.scrbl.

====================================================================================================|#

(provide
  in-queue
  in-queue!
  list->queue
  make-queue
  queue->list
  queue-clear!
  queue-copy
  queue-empty?
  queue-filter
  queue-get!
  queue-length
  queue-map
  queue-peek
  queue-print-mode
  queue-put!
  queue-put!*
  queue-ref
  queue-remove!
  queue?)

(require (only-in compatibility/mlist mlist->list mlist-ref))
(require (for-syntax racket/base))

;=====================================================================================================
; Struct-type for queues. Three fields:
;    length  : natural?            : length of mlist
;    mlist   : mlist?              : contains the elements of the queue.
;    pointer : (or/c null? mpair?) : the last pair of mlist or null if mlist is null.
; For an empty queue length is zero and mlist and pointer are null.

(define (queue-printer q p m)
  (if (queue-print-mode)
    (fprintf p "#<queue:~s:~s>" (queue-length q) (queue-mlist q))
    (fprintf p "#<queue:~s>" (queue-length q))))

(define queue-print-mode (make-parameter #f (λ (x) (and x #t)) 'queue-print-mode))

(struct queue (length (mlist #:auto) (pointer #:auto))
  #:mutable
  #:auto-value '()
  #:inspector (make-sibling-inspector)
  #:property prop:custom-write queue-printer
  #:property prop:sequence (λ (q) (in-queue q))
  #:omit-define-syntaxes)

;=====================================================================================================
; Error handling

(define (check-queue-arg who q)
  (unless (queue? q) (raise-argument-error who "queue?" q)))

(define (queue-empty-error who escape)
  (cond
    ((eq? escape no-escape) (error who "empty queue"))
    ((and (procedure? escape) (procedure-arity-includes? escape 0)) (escape))
    (else escape)))

(define (index-out-of-range escape who index length)
  (cond
    ((eq? escape no-escape)
     (error who
       "index ~s too large~n current length of the queue is ~s"
       index length))
    ((and (procedure? escape) (procedure-arity-includes? escape 0)) (escape))
    (else escape)))

(define no-escape (gensym))

;=====================================================================================================
; Procedures proper
; q-name     : without argument checks, for internal use.
; queue-name : with argument checks, provided.

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define-sequence-syntax in-queue
  (lambda () #'in-queue/proc)
  (lambda (stx)
    (syntax-case stx ()
      (((e) (_ queue-expr))
       #'((e)
          (:do-in
            (((q) queue-expr))
            (check-queue-arg 'in-queue q)
            ((mlist (queue-mlist q)))
            (not (null? mlist))
            (((e) (mcar mlist)))
            #t #t
            ((mcdr mlist)))))
      (_ #f))))

(define in-queue/proc
  (procedure-rename
    (λ (q)
      (check-queue-arg 'in-queue q)
      (q->list q))
    'in-queue))

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define-sequence-syntax in-queue!
  (lambda () #'in-queue!/proc)
  (lambda (stx)
    (syntax-case stx ()
      (((e) (_ queue-expr))
       #'((e)
          (:do-in
            (((q) queue-expr))
            (check-queue-arg 'in-queue! q)
            ()
            (not (q-empty? q))
            (((e) (q-get! q)))
            #t #t
            ())))
      (_ #f))))

(define in-queue!/proc
  (procedure-rename
    (λ (q)
      (error 'in-queue! "valid in for-clauses only"))
    'in-queue!))

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (list->queue list)
  (unless (list? list) (raise-argument-error 'list->queue "list?" list))
  (list->q list))

(define (list->q list)
  (define q (queue 0))
  (define (list->q list)
    (unless (null? list) (q-put! q (car list)) (list->q (cdr list))))
  (list->q list)
  q)

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (make-queue . elements) (list->q elements))

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (queue->list q)
  (check-queue-arg 'queue-ref q)
  (q->list q))

(define (q->list q) (mlist->list (queue-mlist q)))

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (queue-clear! q)
  (check-queue-arg 'queue-clear! q)
  (q-clear! q))

(define (q-clear! q)
  (set-queue-length! q 0)
  (set-queue-mlist! q '())
  (set-queue-pointer! q '()))

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (queue-copy q)
  (check-queue-arg 'queue-copy q)
  (define new-q (queue 0))
  (define (loop mlist)
    (unless (null? mlist)
      (q-put! new-q (mcar mlist))
      (loop (mcdr mlist))))
  (loop (queue-mlist q))
  new-q)

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (queue-empty? q)
  (check-queue-arg 'queue-empty? q)
  (q-empty? q))

(define (q-empty? q) (null? (queue-mlist q)))

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (queue-filter q pred)
  (check-queue-arg 'queue-copy q)
  (define new-q (queue 0))
  (define (queue-filter mlist)
    (unless (null? mlist)
      (define kar (mcar mlist))
      (when (pred kar) (q-put! new-q kar))
      (queue-filter (mcdr mlist))))
  (queue-filter (queue-mlist q))
  new-q)

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (queue-get! q (escape no-escape))
  (check-queue-arg 'queue-get! q)
  (cond
    ((null? (queue-mlist q)) (queue-empty-error 'queue-get! escape))
    (else (q-get! q))))

(define (q-get! q) ; For internal use only.
  (define mlist (queue-mlist q))
  (define e (mcar mlist))
  (define new-mlist (mcdr mlist))
  (set-queue-mlist! q new-mlist)
  (cond
    ((null? new-mlist) (set-queue-length! q 0) (set-queue-pointer! q '()))
    (else (set-queue-length! q (sub1 (queue-length q)))))
  e)

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (queue-map q f)
  (check-queue-arg 'queue-map q)
  (define new-q (queue 0))
  (define (loop mlist)
    (unless (null? mlist)
      (q-put! new-q (f (mcar mlist)))
      (loop (mcdr mlist))))
  (loop (queue-mlist q))
  new-q)

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (queue-peek q (escape no-escape))
  (check-queue-arg 'queue-peek q)
  (define mlist (queue-mlist q))
  (cond
    ((null? mlist) (queue-empty-error 'queue-peek escape))
    (else (mcar mlist))))

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (queue-put! q e)
  (check-queue-arg 'queue-put! q)
  (q-put! q e))

(define (q-put! q e)
  (set-queue-length! q (add1 (queue-length q)))
  (define pointer (queue-pointer q))
  (cond
    ((null? pointer)
     (define mlist (mcons e '()))
     (set-queue-mlist! q mlist)
     (set-queue-pointer! q mlist))
    (else
      (define new-pointer (mcons e '()))
      (set-mcdr! pointer new-pointer)
      (set-queue-pointer! q new-pointer))))

(define (queue-put!* q . elements)
  (check-queue-arg 'queue-put!* q)
  (for ((e (in-list elements))) (q-put! q e)))

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (queue-ref q index (escape no-escape))
  (check-queue-arg 'queue-ref q)
  (unless (exact-nonnegative-integer? index) (raise-argument-error 'queue-ref "natural?" index))
  (define length (queue-length q))
  (cond
    ((>= index length) (index-out-of-range escape 'queue-ref index length))
    (else (mlist-ref (queue-mlist q) index))))

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(define (queue-remove! q index (escape no-escape))
  (check-queue-arg 'queue-remove q)
  (unless (exact-nonnegative-integer? index) (raise-argument-error 'queue-remove! "natural?" index))
  (define length (queue-length q))
  (cond
    ((>= index length) (index-out-of-range escape 'queue-remove! index length))
    ((= index 0) (q-get! q))
    ((= length 1)
     (define e (mcar (queue-mlist q)))
     (set-queue-length! q 0)
     (set-queue-mlist! '())
     (set-queue-pointer! '())
     e)
    (else
      (define (loop k mlist previous-mlist)
        (cond
          ((zero? k)
           (define e (mcar mlist))
           (set-queue-length! q (sub1 length))
           (set-mcdr! previous-mlist (mcdr mlist))
           (when (null? (mcdr mlist)) (set-queue-pointer! q previous-mlist))
           e)
          (else (loop (sub1 k) (mcdr mlist) (mcdr previous-mlist)))))
      (loop (sub1 index) (mcdr (queue-mlist q)) (queue-mlist q)))))

;=====================================================================================================
; End
