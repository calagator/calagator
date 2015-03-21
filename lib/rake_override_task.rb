require "rake"

Rake::TaskManager.class_eval do
  def override_task *args, &block
    name = args.first
    new_name = "#{name}:original"
    @tasks[new_name] = @tasks.delete(name)
    Rake::Task.define_task *args, &block
  end
end

def override_task *args, &block
  Rake.application.override_task *args, &block
end

