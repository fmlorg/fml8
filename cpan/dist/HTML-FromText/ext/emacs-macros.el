;; blockquotes
(global-set-key (kbd "C-c h")
                (lambda () (interactive)
                  (shell-command-on-region
                   (region-beginning) (region-end)
                   "text2html --paras --urls --blockquotes --email --bullets --numbers --tables --bold --underline"
                   (current-buffer) t)))

;; blockparas
(global-set-key (kbd "C-c j")
                (lambda () (interactive)
                  (shell-command-on-region
                   (region-beginning) (region-end)
                   "text2html --paras --urls --blockparas --email --bullets --numbers --tables --bold --underline"
                   (current-buffer) t)))

;; blockcode
(global-set-key (kbd "C-c k")
                (lambda () (interactive)
                  (shell-command-on-region
                   (region-beginning) (region-end)
                   "text2html --paras --urls --blockcode --email --bullets --numbers --tables --bold --underline"
                   (current-buffer) t)))
