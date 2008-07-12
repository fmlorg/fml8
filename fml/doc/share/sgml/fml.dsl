<!-- $FML: fml.dsl,v 1.7 2005/07/27 12:20:52 fukachan Exp $ -->

<!DOCTYPE style-sheet PUBLIC "-//James Clark//DTD DSSSL Style Sheet//EN" [
   <!ENTITY docbook.dsl PUBLIC "-//Norman Walsh//DOCUMENT DocBook HTML Stylesheet//EN" CDATA DSSSL>

<!ENTITY % output.html          "INCLUDE">
<!ENTITY % output.html.images   "INCLUDE">
<!ENTITY % output.print         "IGNORE">
<!ENTITY % output.print.pdf     "IGNORE">

<![ %output.html; [
<!ENTITY docbook.dsl PUBLIC "-//Norman Walsh//DOCUMENT DocBook HTML Stylesheet//EN"
CDATA DSSSL>
]]>
<![ %output.print; [
<!ENTITY docbook.dsl PUBLIC "-//Norman Walsh//DOCUMENT DocBook Print Stylesheet//EN"
 CDATA DSSSL>

]]>

]>

<style-sheet>
  <style-specification use="docbook">
    <style-specification-body>

      <![ %output.html; [ 

        (define %root-filename%
          ;; Name for the root HTML document
          "index")

        (define %html-ext%
          ;; Default extension for HTML output files
          ".html")

      (define %use-id-as-filename%
          ;; Use ID attributes as name for component HTML files?
          #t)

        (define ($html-body-end$)
          (if (equal? $email-footer$ (normalize ""))
            (empty-sosofo)
            (make sequence
              (if nochunks
                  (make empty-element gi: "hr")
                  (empty-sosofo))
              ($email-footer$))))

	(define ($email-footer$)
          (make sequence

              (make element gi: "small"
                 attributes: (list (list "align" "center"))

                (literal "fml 8.0 (fml-devel) project homepage is ")
	        (make element gi: "a"
                      attributes: 
                     (list (list "href" "http://www.fml.org/software/fml8/")
                            (list "target" "_top"))
                  (literal "www.fml.org/software/fml8/"))
                (literal "."))

                (make empty-element gi: "br")

              (make element gi: "small"

                (literal "fml 4.0 project homepage is ")
	        (make element gi: "a"
                      attributes: 
                     (list (list "href" "http://www.fml.org/software/fml4/")
                            (list "target" "_top"))
                  (literal "www.fml.org/software/fml4/"))
                (literal "."))

                (make empty-element gi: "br")

              (make element gi: "small"
                (literal "about one floppy bsd routers, see ")
	        (make element gi: "a"
                      attributes: 
                     (list (list "href" "http://www.bsdrouter.org/")
                            (list "target" "_top"))
                  (literal "www.bsdrouter.org/"))
                (literal "."))

                (make empty-element gi: "br")

              (make element gi: "small"
                (literal "other free softwares are found at ")
	        (make element gi: "a"
                      attributes: 
                      (list (list "href" "http://www.fml.org/software/") 
                            (list "target" "_top"))
                  (literal "www.fml.org/software/"))
                (literal "."))

                (make empty-element gi: "br")


	    (make element gi: "p"
              (make element gi: "small"
                (literal "author's homepage is ")
	        (make element gi: "a"
                      attributes: 
                      (list (list "href" "http://www.fml.org/home/fukachan/") 
                            (list "target" "_top"))
                  (literal "www.fml.org/home/fukachan/"))
                (literal "."))

                (make empty-element gi: "br")

              (make element gi: "small"
                (literal "Also, visit nuinui's world :) at ")
	        (make element gi: "a"
                      attributes: 
                     (list (list "href" "http://www.nuinui.net/")
                            (list "target" "_top"))
                  (literal "www.nuinui.net"))
                (literal "."))

                (make empty-element gi: "br")

              (make element gi: "p"
                (literal "For questions about FML, e-mail <")
                (make element gi: "a"
                      attributes: (list (list "href" "mailto:fml-bugs@fml.org"))
                  (literal "fml-bugs@fml.org"))
	        (literal ">.")))))

      ]]>

    </style-specification-body>
  </style-specification>

  <external-specification id="docbook" document="docbook.dsl">
</style-sheet>
