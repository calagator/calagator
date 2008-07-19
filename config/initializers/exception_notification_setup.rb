# Specifies the recipients of exception emails. Encodes the addresses using
# trivial obfuscation to limit the number of robots that get our email
# addresses. To generate this string, use the result of a command like:
#   ['you@host.ext'].pack('u')
ExceptionNotifier.exception_recipients = "<:6=A;\"ME<G)O<D!P<F%G;6%T:6-R869T+F-O;0``\n".unpack("u")
ExceptionNotifier.email_prefix = "[ERROR calagator] "
