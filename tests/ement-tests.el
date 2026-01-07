;;; ement-tests.el --- Tests for Ement.el                  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Free Software Foundation, Inc.

;; Author: Adam Porter <adam@alphapapa.net>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:

(require 'ert)
(require 'map)

(require 'ement-lib)

;;;; Tests

(ert-deftest ement--format-body-mentions ()
  (let ((room (make-ement-room
               :members (map-into
                         `(("@foo:matrix.org" . ,(make-ement-user :id "@foo:matrix.org"
                                                                  :displayname "foo"))
                           ("@bar:matrix.org" . ,(make-ement-user :id "@bar:matrix.org"
                                                                  :displayname "bar")))
                         '(hash-table :test equal)))))
    (should (equal (ement--format-body-mentions "@foo: hi" room)
                   "<a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>: hi"))
    (should (equal (ement--format-body-mentions "@foo:matrix.org: hi" room)
                   "<a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>: hi"))
    (should (equal (ement--format-body-mentions "foo: hi" room)
                   "<a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>: hi"))
    (should (equal (ement--format-body-mentions "@foo and @bar:matrix.org: hi" room)
                   "<a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a> and <a href=\"https://matrix.to/#/@bar:matrix.org\">bar</a>: hi"))
    (should (equal (ement--format-body-mentions "foo: how about you and @bar ..." room)
                   "<a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>: how about you and <a href=\"https://matrix.to/#/@bar:matrix.org\">bar</a> ..."))
    (should (equal (ement--format-body-mentions "Hello, @foo:matrix.org." room)
                   "Hello, <a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>."))
    (should (equal (ement--format-body-mentions "Hello, @foo:matrix.org, how are you?" room)
                   "Hello, <a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>, how are you?"))))

(ert-deftest ement-room--event-mentions-user-p ()
  (let* ((user (make-ement-user :id "@test:matrix.org"
                                :username "test"
                                :displayname "Test User"))
         (user-with-period (make-ement-user :id "@test.user:matrix.org"
                                            :username "test.user"
                                            :displayname "Test User"))
         (user-with-hyphen (make-ement-user :id "@test-user:matrix.org"
                                            :username "test-user"
                                            :displayname "Test User"))
         (room (make-ement-room :displaynames (let ((table (make-hash-table :test 'equal)))
                                                (puthash user "Test User" table)
                                                table)))
         (event (make-ement-event)))
    (cl-macrolet ((test-mention (user body result)
                    `(progn
                       (setf (ement-event-content event) (list (cons 'body ,body)))
                       (should (equal ,result (if (ement-room--event-mentions-user-p event ,user room) t nil))))))

      (test-mention user "hello test" t)
      (test-mention user "hello test." t)
      ;; (test-mention user "hello test-name" nil)
      (test-mention user "hello @test" t)
      (test-mention user "the latest" nil)
      (test-mention user "hello testing" nil)
      (test-mention user "hellotest" nil)

      (test-mention user "hello @test:matrix.org" t)
      (test-mention user "@test:matrix.org" t)

      (test-mention user-with-period "hello test.user" t)
      (test-mention user-with-period "@test.user" t)
      (test-mention user-with-period "test.username" nil)

      (test-mention user-with-hyphen "hello test-user" t)
      ;; (test-mention user-with-hyphen "test-user-name" nil)
      )))

(provide 'ement-tests)

;;; ement-tests.el ends here
