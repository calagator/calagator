SAMPLES_PATH = File.expand_path(File.dirname(__FILE__) + "/samples") unless defined?(SAMPLES_PATH)

def read_sample(path_fragment)
  File.read(File.join(SAMPLES_PATH, path_fragment))
end
