# Copyright 2014 G. Allen Morris III
#
# This file may be used under the terms of the GNU General Public
# License version 2.0 as published by the Free Software Foundation
# and appearing in the file LICENSE.GPL included in the packaging of
# this file.  Please review the following information to ensure GNU
# General Public Licensing requirements will be met:
# http://www.trolltech.com/products/qt/opensource.html
#
# This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
# WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# Used to prevent the class/module from being loaded more than once
raise "error" if defined? SqlAutoDoc::VERSION
unless defined? SqlAutoDoc::VERSION
  module SqlAutoDoc
    module VERSION
      MAJOR = 0
      MINOR = 1
      TINY  = 0

      STRING = [MAJOR, MINOR, TINY].join('.')
    end
  end
end

