module Kernel

  # Supress errors while executing a block, with execptions.
  #
  # TODO: This will be deprecatd in favor or Exception#suppress.
  #
  #  CREDIT: David Heinemeier Hansson

  def suppress(*exception_classes)
    warn "use Exception#supress for future versions"
    begin yield
    rescue Exception => e
      raise unless exception_classes.any? { |cls| e.kind_of?(cls) }
    end
  end

end

