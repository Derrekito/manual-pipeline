# Logo Assets

`example-logo.pdf` is a placeholder showing where a logo goes on the title
page. It is drawn by `example-logo.tex`; edit that and rebuild with

    lualatex example-logo.tex

Name a logo in a document's front matter to put it on the title page, or
leave `logo` out for none:

    logo: example-logo.pdf
    logo-width: 0.25\textwidth

Your own logos belong in your project's `manual/assets/logos/`, which is
searched before this directory. Logo files here other than the example are
git-ignored, so nothing proprietary is committed by accident.
