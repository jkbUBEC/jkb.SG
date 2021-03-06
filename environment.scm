;; Copyright (C) 2017, 2018, 2019, 2020  Roel Janssen

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(use-modules (guix packages)
             ((guix licenses) #:prefix license:)
             (gnu packages autotools)
             (gnu packages bioinformatics)
             (gnu packages certs)
             (gnu packages compression)
             (gnu packages curl)
             (gnu packages gnupg)
             (gnu packages guile)
             (gnu packages guile-xyz)
             (gnu packages image)
             (gnu packages linux)
             (gnu packages openldap)
             (gnu packages pkg-config)
             (gnu packages rdf)
             (gnu packages tex)
             (gnu packages tls)
             (gnu packages xml)
             (gnu packages)
             (guix build utils)
             (guix build-system gnu)
             (guix download)
             (guix git-download)
             (guix packages)
             (ice-9 format)
             (ice-9 rdelim))

(define sparqling-genomics
  (package
   (name "sparqling-genomics")
   (version "0.99.11")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "https://github.com/UMCUGenetics/sparqling-genomics/"
                  "releases/download/" version "/sparqling-genomics-"
                  version ".tar.gz"))
            (sha256
             (base32
              "114sjnm850gj63jsiqk22dc5g4pd297qigj4ggpavb20k0k7yn30"))))
   (build-system gnu-build-system)
   (arguments
    `(#:configure-flags (list (string-append
                               "--with-libldap-prefix="
                               (assoc-ref %build-inputs "openldap")))
      #:phases
      (modify-phases %standard-phases
        (add-after 'install 'wrap-executable
          (lambda* (#:key inputs outputs #:allow-other-keys)
            (let* ((out  (assoc-ref outputs "out"))
                   (certs (assoc-ref inputs "nss-certs"))
                   (certs-dir (string-append certs "/etc/ssl/certs")))
              (wrap-program (string-append out "/bin/sg-web")
                `("SSL_CERT_DIR" ":" = (,certs-dir)))
              (wrap-program (string-append out "/bin/sg-auth-manager")
                `("SSL_CERT_DIR" ":" = (,certs-dir)))))))))
   (native-inputs
    `(("texlive" ,texlive)
      ("autoconf" ,autoconf)
      ("automake" ,automake)
      ("libtool" ,libtool)
      ("pkg-config" ,pkg-config)))
   (inputs
    `(("guile" ,guile-3.0)
      ("fuse" ,fuse)
      ("htslib" ,htslib)
      ("gnutls" ,gnutls)
      ("libpng" ,libpng)
      ("libxml2" ,libxml2)
      ("nss-certs" ,nss-certs)
      ("openldap" ,openldap)
      ("raptor2" ,raptor2)
      ("xz" ,xz)
      ("zlib" ,zlib)))
   (home-page "https://github.com/UMCUGenetics/sparqling-genomics")
   (synopsis "Tools to use SPARQL to analyze genomics data")
   (description "This package provides various tools to extract RDF triples
from genomic data formats, and a web interface to query SPARQL endpoints.")
   ;; All programs except the web interface is licensed GPLv3+.  The web
   ;; interface is licensed AGPLv3+.
   (license (list license:gpl3+ license:agpl3+))))

;; Evaluate to the complete recipe, so that the development
;; environment has everything to start from scratch.
sparqling-genomics
