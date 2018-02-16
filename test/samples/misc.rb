# Collect diverse tricky pieces of code here
#

enc = __ENCODING__

# https://github.com/seattlerb/ruby_parser/issues/250
self[:x]

# https://github.com/seattlerb/ruby_parser/pull/254
def foo a:, b:
  # body
end
