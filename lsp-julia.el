;;; lsp-julia.el --- Julia support for lsp-mode

;; Copyright (C) 2017 Martin Wolke, 2018 Adam Beckmeyer

;; Author: Martin Wolke <vibhavp@gmail.com>
;;         Adam Beckmeyer <adam_git@thebeckmeyers.xyz>
;; Maintainer: Adam Beckmeyer <adam_git@thebeckmeyers.xyz>
;; Version: 0.1.0
;; Package-Requires: (lsp-mode)
;; Keywords: languages, tools
;; URL: https://github.com/non-Jedi/lsp-julia

;;; Code:
(require 'lsp-mode)

(defcustom lsp-julia-command "julia"
  "Command to invoke julia with."
  :type 'string
  :group 'lsp-julia)

(defcustom lsp-julia-flags '("--startup-file=no" "--history-file=no")
  "List of additional flags to call julia with."
  :type '(repeat (string :tag "argument"))
  :group 'lsp-julia)

(defcustom lsp-julia-timeout 30
  "Time before lsp-mode should assume julia just ain't gonna start."
  :group 'lsp-julia)

(defun lsp-julia--get-root ()
  "Try to find the package directory by searching for a Project.toml file.
If no .gitignore file can be found use the default directory "

  (let ((dir (locate-dominating-file default-directory "Project.toml")))
    (if dir (expand-file-name dir)
      (expand-file-name lsp-julia-default-environment))))



(defvar lsp-julia-debug t
  "debug mode")

(defun lsp-julia--command ()
  `(,lsp-julia-command
    ,@lsp-julia-flags
    ,(concat "-e using LanguageServer, Sockets, SymbolServer;"
             " server = LanguageServer.LanguageServerInstance("
             " stdin, stdout, "
             (if lsp-julia-debug "true" "false")
             ","
             " \"" (lsp-julia--get-root) "\","
             " \"\", Dict());"
             " server.runlinter = false;"
             " run(server);")))

(defconst lsp-julia--handlers
  '(("window/setStatusBusy" .
     (lambda (w _p)))
    ("window/setStatusReady" .
     (lambda(w _p)))))

(defcustom lsp-julia-default-environment "~/.julia/environments/v1.0"
  "The path to the default environment."
  :type 'string
  :group 'lsp-julia)

(defun lsp-julia--get-root ()
  (let ((dir (locate-dominating-file default-directory "Project.toml")))
    (if dir (expand-file-name dir)
      (expand-file-name lsp-julia-default-environment))))


(defun lsp-julia--initialize-client(client)
  (mapcar #'(lambda (p) (lsp-client-on-notification client (car p) (cdr p))) lsp-julia--handlers)
  (setq-local lsp-response-timeout lsp-julia-timeout))


(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection 'lsp-julia--command)
  :major-modes '(julia-mode)
  :server-id 'ls.jl
  :initialization-options 'lsp-julia--rls-flags))

(provide 'lsp-julia)
;;; lsp-julia.el ends here
