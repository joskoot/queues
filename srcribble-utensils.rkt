#lang scribble/manual

@;====================================================================================================

@(require
   scribble/core
   scribble/eval
   racket
   "queue.rkt"
   (for-label "queue.rkt" racket)
   (for-template "queue.rkt" racket)
   (for-syntax racket))

@(provide (all-defined-out))

@(print-reader-abbreviations #f)
@(print-as-expression #f)
@(begin-for-syntax
   (print-reader-abbreviations #f)
   (print-as-expression #f))

@(define-syntax-rule
   (Interaction x ...)
   (interaction
     #:eval
     (make-base-eval #:pretty-print? #f
       #:lang '(begin (require racket "queue.rkt")
                 (begin-for-syntax
                   (print-reader-abbreviations #f)
                   (print-as-expression #f))
                 (print-reader-abbreviations #f)
                 (print-as-expression #f)))
     x ...))

@(define-syntax-rule
   (Interaction* x ...)
   (interaction #:eval evaller x ...))

@(define (make-evaller)
   (make-base-eval #:pretty-print? #f
     #:lang '(begin (require racket "queue.rkt")
               (begin-for-syntax
                 (print-reader-abbreviations #f)
                 (print-as-expression #f))
               (print-reader-abbreviations #f)
               (print-as-expression #f))))

@(define evaller (make-evaller))
@(define (reset-Interaction*) (set! evaller (make-evaller)))
@(define lb linebreak)
@(define nb nonbreaking)
@; ignore is a syntax such as to prevent arguments to be evaluated.
@(define-syntax-rule (ignore x ...) (void))
@; Below syntaxes are used such as to allow keyword arguments
@; without explicitly mentioning them in the definitions.
@(define-syntax-rule (nbsl x ...) (nb (seclink    x ...)))
@(define-syntax-rule (nbsr x ...) (nb (secref     x ...)))
@(define-syntax-rule (nbhl x ...) (nb (hyperlink  x ...)))
@(define-syntax-rule (nber x ...) (nb (elemref    x ...)))
@(define-syntax-rule (Nber x y ...) (nb (elemref x (tt (list y ...)))))
@(define-syntax-rule (nbrl x ...) (nb (racketlink x ...)))
@(define-syntax-rule (nbr  x ...) (nb (racket     x ...)))
@(define-syntax-rule (nbpr x) (nber x (tt x)))
@(define-syntax-rule (defmacro x ...) (defform #:kind "macro" #:link-target? #f x ...))
@(define-syntax-rule (defmacro* x ...) (defform* #:kind "macro" #:link-target? #f x ...))
@(define-syntax-rule (deffun x ...) (defproc #:link-target? #f x ...))
@(define-syntax-rule (defpred x ...) (defproc #:kind "predicate" #:link-target? #f x ...))
@(define (tt . content) (element 'tt (apply list content)))
@(define(minus) (tt "-"))
@(define(-?) (element "roman" ?-))
@(define (note . x) (inset (apply smaller x)))
@(define (inset . x) (apply nested #:style 'inset x))
@(define (expt-1) @↑{@(minus)1})
@(define ↑ superscript)
@(define ↓ subscript)
@(define-syntax-rule (Tabular ((e ...) ...) . rest) (tabular (list (list e ...) ...) . rest))
@(define (roman . x) (element 'roman x))
@(define (nbtt x) (nb (ttblack x)))
@(define (itt . content) (italic (apply tt content)))

@(define Void
   (let
     ((x
        (seclink
          "void"
          #:doc '(lib "scribblings/reference/reference.scrbl") (nb (tt "#<void>")))))
     (λ () x)))

@(define-syntax-rule (Tabular-with-linebreaks ((e ...) ... (le ...)) . rest)
   (Tabular (((list e (lb) (hspace 1)) ...) ... (le ...)) . rest))

@(define (make-color-style color)
   (define prop:color (color-property color))
   (define color-style (style #f (list prop:color)))
   (lambda elems (element 'roman (element color-style elems))))

@(define (make-ttcolor-style color)
   (define prop:color (color-property color))
   (define color-style (style #f (list prop:color)))
   (lambda elems (element 'tt (element color-style elems))))

@(define red       (make-color-style   "red"))
@(define green     (make-color-style   "green"))
@(define blue      (make-color-style   "blue"))
@(define black     (make-color-style   "black"))
@(define ttblack   (make-ttcolor-style "black"))
@(define ttred     (make-ttcolor-style "red"))
@(define ttgreen   (make-ttcolor-style "green"))
@(define ttpurple    (make-ttcolor-style "purple"))
@(define optional "optional, evaluated, default: ")
@(define opt-proc "optional, default: ")

@(define (Rckt) (nbhl "https://docs.racket-lang.org/reference/index.html" "Racket"))
@(define (DrRckt) (nbhl "https://docs.racket-lang.org/drracket/index.html" "DrRacket"))
@(define (keyword . x)
   (apply seclink "keywords" #:doc '(lib "scribblings/reference/reference.scrbl") x))

@(define-syntax-rule (Elemtag x) (add-elem-tag x))

@(define add-elem-tag (let ((tags '())) (λ ((x 'not-present))
                                          (cond
                                            ((eq? x 'not-present) tags)
                                            (else (set! tags (cons x tags))
                                              (elemtag x))))))
