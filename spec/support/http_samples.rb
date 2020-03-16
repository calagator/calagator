# frozen_string_literal: true

unless defined?(SAMPLES_PATH)
  SAMPLES_PATH = File.expand_path(File.dirname(__FILE__) + '/samples')
end

def read_sample(path_fragment)
  File.read(File.join(SAMPLES_PATH, path_fragment))
end
