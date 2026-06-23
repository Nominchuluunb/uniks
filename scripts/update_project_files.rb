#!/usr/bin/env ruby
# Updates the Xcode project file references for the Uniks scaffold.

require 'xcodeproj'

PROJECT_PATH = 'uniks.xcodeproj'

UNIKS_FILES = [
  'uniks/uniksApp.swift',
  'uniks/ContentView.swift',
  'uniks/Core/Models/HabitEvent.swift',
  'uniks/Core/Protocols/LocalLLMEngine.swift',
  'uniks/Core/Actors/ParsingActor.swift',
  'uniks/Core/Engines/OllamaLLMEngine.swift',
  'uniks/Core/Engines/MLXLLMEngine.swift',
  'uniks/Core/Services/ModelContainer+Factory.swift',
  'uniks/Core/Services/FTSService.swift',
  'uniks/UI/Shared/StatusBadge.swift'
].freeze

TEST_FILES = [
  'uniksTests/MockLLMEngine.swift',
  'uniksTests/HabitEventTests.swift',
  'uniksTests/HabitParseResultTests.swift',
  'uniksTests/ParsingActorTests.swift',
  'uniksTests/MLXLLMEngineTests.swift',
  'uniksTests/FTSServiceTests.swift',
  'uniksTests/OllamaLLMEngineTests.swift'
].freeze

REMOVE_FILES = [
  'uniks/Item.swift',
  'uniksTests/uniksTests.swift',
  'uniks/Core/Actors/MLXLLMEngine.swift'
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)

# Remove legacy files from project and disk.
REMOVE_FILES.each do |path|
  file_ref = project.files.find { |f| f.full_path == path }
  if file_ref
    file_ref.remove_from_project
    puts "Removed project reference: #{path}"
  end
  if File.exist?(path)
    File.delete(path)
    puts "Deleted file: #{path}"
  end
end

# Helper to add files to a target while preserving group structure.
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
    puts "File already referenced: #{file_path}"
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

uniks_target = project.targets.find { |t| t.name == 'uniks' }
test_target = project.targets.find { |t| t.name == 'uniksTests' }

UNIKS_FILES.each do |path|
  add_file_to_target(project, uniks_target, path)
end

TEST_FILES.each do |path|
  add_file_to_target(project, test_target, path)
end

project.save
puts "Project saved."
