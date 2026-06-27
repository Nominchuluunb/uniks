#!/usr/bin/env ruby
# Updates the Xcode project file references for Uniks.
# Run: ruby scripts/update_project_files.rb

require 'xcodeproj'

PROJECT_PATH = 'uniks.xcodeproj'

# All source files for the main target (auto-discovered from disk)
UNIKS_DIR = 'uniks'
TEST_DIR = 'uniksTests'

project = Xcodeproj::Project.open(PROJECT_PATH)

uniks_target = project.targets.find { |t| t.name == 'uniks' }
test_target = project.targets.find { |t| t.name == 'uniksTests' }

def add_file_to_target(project, target, file_path)
  components = file_path.split('/')
  file_name = components.pop

  group = project.main_group
  components.each do |component|
    existing = group.children.find { |g| g.display_name == component && g.is_a?(Xcodeproj::Project::Object::PBXGroup) }
    group = existing || group.new_group(component, component)
  end

  existing_file = group.files.find { |f| f.path == file_name }
  if existing_file
    file_ref = existing_file
  else
    file_ref = group.new_file(file_name)
    puts "Added file reference: #{file_path}"
  end

  unless target.source_build_phase.files_references.include?(file_ref)
    target.source_build_phase.add_file_reference(file_ref)
    puts "  Linked #{file_path} to #{target.name}"
  end

  file_ref
end

# Discover and add all Swift files in uniks/
Dir.glob("#{UNIKS_DIR}/**/*.swift").sort.each do |path|
  add_file_to_target(project, uniks_target, path)
end

# Discover and add all Swift files in uniksTests/
Dir.glob("#{TEST_DIR}/**/*.swift").sort.each do |path|
  add_file_to_target(project, test_target, path)
end

project.save
puts "Project saved with #{Dir.glob("#{UNIKS_DIR}/**/*.swift").count} source files and #{Dir.glob("#{TEST_DIR}/**/*.swift").count} test files."
