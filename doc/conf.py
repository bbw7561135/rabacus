# -*- coding: utf-8 -*-
#
# Idle Hands documentation build configuration file, created by
# sphinx-quickstart on Sun Dec 22 22:26:33 2013.
#
# This file is execfile()d with the current directory set to its containing dir.
#
# Note that not all possible configuration values are present in this
# autogenerated file.
#
# All configuration values have a default; values that are commented out
# serve to show the default.

import sys, os
import cloud_sptheme as csp

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#sys.path.insert(0, os.path.abspath('.'))

# -- General configuration -----------------------------------------------------

# If your documentation needs a minimal Sphinx version, state it here.
#needs_sphinx = '1.0'

# Add any Sphinx extension module names here, as strings. They can be extensions
# coming with Sphinx (named 'sphinx.ext.*') or your custom ones.

extensions = ['sphinx.ext.autodoc', 'sphinx.ext.doctest', 
              'sphinx.ext.pngmath', 'sphinx.ext.viewcode', 
              'sphinx.ext.autosummary',
              'cloud_sptheme.ext.index_styling',
              'cloud_sptheme.ext.relbar_toc']

#pngmath_latex_preamble=r'\usepackage[active]{preview}'
#png_use_preview = True
#pngmath_dvipng_args = ['-gamma', '1.5', '-D', '150', '-bg', 'Transparent']

#extensions = ['sphinx.ext.autodoc', 'sphinx.ext.doctest', 
#              'sphinx.ext.mathjax', 'sphinx.ext.viewcode', 
#              'sphinx.ext.autosummary',
#              'cloud_sptheme.ext.index_styling',
#              'cloud_sptheme.ext.relbar_toc']

# Add any paths that contain templates here, relative to this directory.
templates_path = ['templates']

# The suffix of source filenames.
source_suffix = '.rst'

# The encoding of source files.
#source_encoding = 'utf-8-sig'

# The master toctree document.
master_doc = 'index'

# General information about the project.
project = u'Rabacus'
copyright = u'2014, Gabriel Altay'

# The version info for the project you're documenting, acts as replacement for
# |version| and |release|, also used in various other places throughout the
# built documents.
#
# The short X.Y version.
version = '0.9'
# The full version, including alpha/beta/rc tags.
release = '0.9.0'

# The language for content autogenerated by Sphinx. Refer to documentation
# for a list of supported languages.
#language = None

# There are two options for replacing |today|: either, you set today to some
# non-false value, then it is used:
#today = ''
# Else, today_fmt is used as the format for a strftime call.
#today_fmt = '%B %d, %Y'

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
exclude_patterns = ['build']

# The reST default role (used for this markup: `text`) to use for all documents.
#default_role = None

# If true, '()' will be appended to :func: etc. cross-reference text.
#add_function_parentheses = True

# If true, the current module name will be prepended to all description
# unit titles (such as .. function::).
#add_module_names = True

# If true, sectionauthor and moduleauthor directives will be shown in the
# output. They are ignored by default.
#show_authors = False

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

# A list of ignored prefixes for module index sorting.
#modindex_common_prefix = []


# -- Options for HTML output ---------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#html_theme = 'default'
#html_theme = 'sphinxdoc'
#html_theme = 'pyramid'
#html_theme = 'haiku'
#html_theme = 'epub'
html_theme = 'cloud'
#html_theme = 'redcloud'

# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
#html_theme_options = {}

#html_theme_options = {
#    "rightsidebar": "true",
#    "relbarbgcolor": "black"
#}


# Add any paths that contain custom themes here, relative to this directory.
#html_theme_path = []

# set the theme path to point to cloud's theme data
html_theme_path = [csp.get_theme_dir()]


# The name for this set of Sphinx documents.  If None, it defaults to
# "<project> v<release> documentation".
#html_title = None

# A shorter title for the navigation bar.  Default is the same as html_title.
#html_short_title = None

# The name of an image file (relative to this directory) to place at the top
# of the sidebar.
#html_logo = None

# The name of an image file (within the static path) to use as favicon of the
# docs.  This file should be a Windows icon file (.ico) being 16x16 or 32x32
# pixels large.
#html_favicon = None

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['static']

# If not '', a 'Last updated on:' timestamp is inserted at every page bottom,
# using the given strftime format.
#html_last_updated_fmt = '%b %d, %Y'

# If true, SmartyPants will be used to convert quotes and dashes to
# typographically correct entities.
#html_use_smartypants = True

# Custom sidebar templates, maps document names to template names.
#html_sidebars = {}

# Additional templates that should be rendered to pages, maps page names to
# template names.
#html_additional_pages = {}

# If false, no module index is generated.
#html_domain_indices = True

# If false, no index is generated.
#html_use_index = True

# If true, the index is split into individual pages for each letter.
#html_split_index = False

# If true, links to the reST sources are added to the pages.
#html_show_sourcelink = True

# If true, "Created using Sphinx" is shown in the HTML footer. Default is True.
#html_show_sphinx = True

# If true, "(C) Copyright ..." is shown in the HTML footer. Default is True.
#html_show_copyright = True

# If true, an OpenSearch description file will be output, and all pages will
# contain a <link> tag referring to it.  The value of this option must be the
# base URL from which the finished HTML is served.
#html_use_opensearch = ''

# This is the file name suffix for HTML files (e.g. ".xhtml").
#html_file_suffix = None

# Output file base name for HTML help builder.
htmlhelp_basename = 'RabacusDoc'


# -- Options for LaTeX output --------------------------------------------------

latex_elements = {
# The paper size ('letterpaper' or 'a4paper').
#'papersize': 'letterpaper',

# The font size ('10pt', '11pt' or '12pt').
#'pointsize': '10pt',

# Additional stuff for the LaTeX preamble.
#'preamble': '',
}

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title, author, documentclass [howto/manual]).
latex_documents = [
  ('index', 'Rabacus.tex', u'Rabacus Documentation',
   u'Gabriel Altay', 'manual'),
]

# The name of an image file (relative to this directory) to place at the top of
# the title page.
#latex_logo = None

# For "manual" documents, if this is true, then toplevel headings are parts,
# not chapters.
#latex_use_parts = False

# If true, show page references after internal links.
#latex_show_pagerefs = False

# If true, show URL addresses after external links.
#latex_show_urls = False

# Documents to append as an appendix to all manuals.
#latex_appendices = []

# If false, no module index is generated.
#latex_domain_indices = True


# -- Options for manual page output --------------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
man_pages = [
    ('index', 'rabacus', u'Rabacus Documentation',
     [u'Gabriel Altay'], 1)
]

# If true, show URL addresses after external links.
#man_show_urls = False


# -- Options for Texinfo output ------------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
texinfo_documents = [
  ('index', 'Rabacus', u'Rabacus Documentation',
   u'Gabriel Altay', 'Rabacus', 'Radiative Transfer Abacus.',
   'Miscellaneous'),
]

# Documents to append as an appendix to all manuals.
#texinfo_appendices = []

# If false, no module index is generated.
#texinfo_domain_indices = True

# How to display URL addresses: 'footnote', 'no', or 'inline'.
#texinfo_show_urls = 'footnote'


autoclass_content = 'both'



rst_prolog = r"""
.. |nH| replace:: :math:`n_{\rm _H}`
.. |nHe| replace:: :math:`n_{\rm _{He}}`

.. |nH1| replace:: :math:`n_{\rm _{HI}}`
.. |nH2| replace:: :math:`n_{\rm _{HII}}`
.. |nHe1| replace:: :math:`n_{\rm _{HeI}}`
.. |nHe2| replace:: :math:`n_{\rm _{HeII}}`
.. |nHe3| replace:: :math:`n_{\rm _{HeIII}}`

.. |xH1| replace:: :math:`x_{\rm _{HI}}`
.. |xH2| replace:: :math:`x_{\rm _{HII}}`
.. |xHe1| replace:: :math:`x_{\rm _{HeI}}`
.. |xHe2| replace:: :math:`x_{\rm _{HeII}}`
.. |xHe3| replace:: :math:`x_{\rm _{HeIII}}`

.. |Inu| replace:: :math:`I_{\nu}` 
.. |Fu| replace:: :math:`F_{u}` 
.. |u| replace:: :math:`u` 
.. |Fn| replace:: :math:`F_{n}` 
.. |n| replace:: :math:`n` 

.. |H1i| replace:: :math:`\Gamma_{\rm _{HI}}` 
.. |He1i| replace:: :math:`\Gamma_{\rm _{HeI}}` 
.. |He2i| replace:: :math:`\Gamma_{\rm _{HeII}}`

.. |H1h| replace:: :math:`H_{\rm _{HI}}` 
.. |He1h| replace:: :math:`H_{\rm _{HeI}}` 
.. |He2h| replace:: :math:`H_{\rm _{HeII}}`

.. |dLu_dnu| replace:: :math:`dL_{u}/d\nu`
.. |dLn_dnu| replace:: :math:`dL_{n}/d\nu`
.. |dLu_dE| replace:: :math:`dL_{u}/dE`
.. |dLn_dE| replace:: :math:`dL_{n}/dE`

.. |dFu_dnu| replace:: :math:`dF_{u}/d\nu`
.. |du_dnu| replace:: :math:`du/d\nu` 
.. |dFn_dnu| replace:: :math:`dF_{n}/d\nu` 
.. |dn_dnu| replace:: :math:`dn/d\nu` 

.. |dFu_dE| replace:: :math:`dF_{u}/dE` 
.. |du_dE| replace:: :math:`du/dE` 
.. |dFn_dE| replace:: :math:`dF_{n}/dE` 
.. |dn_dE| replace:: :math:`dn/dE` 

.. |dH1i_dnu| replace:: :math:`d\Gamma_{\rm _{HI}}/d\nu` 
.. |dH1h_dnu| replace:: :math:`dH_{\rm _{HI}}/d\nu` 
.. |dHe1i_dnu| replace:: :math:`d\Gamma_{\rm _{HeI}}/d\nu` 
.. |dHe1h_dnu| replace:: :math:`dH_{\rm _{HeI}}/d\nu` 
.. |dHe2i_dnu| replace:: :math:`d\Gamma_{\rm _{HeII}}/d\nu`
.. |dHe2h_dnu| replace:: :math:`dH_{\rm _{HeII}}/d\nu`

.. |dH1i_dE| replace:: :math:`d\Gamma_{\rm _{HI}}/dE`
.. |dH1h_dE| replace:: :math:`dH_{\rm _{HI}}/dE`
.. |dHe1i_dE| replace:: :math:`d\Gamma_{\rm _{HeI}}/dE`
.. |dHe1h_dE| replace:: :math:`dH_{\rm _{HeI}}/dE`
.. |dHe2i_dE| replace:: :math:`d\Gamma_{\rm _{HeII}}/dE`
.. |dHe2h_dE| replace:: :math:`dH_{\rm _{HeII}}/dE`
"""
