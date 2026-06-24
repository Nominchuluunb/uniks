#!/usr/bin/env ruby
# Adds required Swift Package Manager dependencies to the Uniks Xcode project.

require 'xcodeproj'

PROJECT_PATH = 'uniks.xcodeproj'

DEPENDENCIES = [
  {
    name: 'mlx-swift-lm',
    url: 'https://github.com/ml-explore/mlx-swift-lm.git',
    branch: 'main',
    products: {
      'uniks' => ['MLXLMCommon', 'MLXLLM', 'MLXHuggingFace'],
      'uniksTests' => ['MLXLMCommon', 'MLXLLM', 'MLXHuggingFace']
    }
  },
  {
    name: 'swift-huggingface',
    url: 'https://github.com/huggingface/swift-huggingface.git',
    version: '0.9.0',
    products: {
      'uniks' => ['HuggingFace'],
      'uniksTests' => ['HuggingFace']
    }
  },
  {
    name: 'swift-transformers',
    url: 'https://github.com/huggingface/swift-transformers.git',
    version: '1.3.3',
    products: {
      'uniks' => ['Tokenizers'],
      'uniksTests' => ['Tokenizers']
    }
  },
  {
    name: 'SwiftFTS',
    url: 'https://github.com/cbess/SwiftFTS.git',
    branch: 'main',
    products: {
      'uniks' => ['SwiftFTS'],
      'uniksTests' => ['SwiftFTS']
    }
  }
]

# Legacy package references that should be removed.
REMOVE_PACKAGE_URLS = [
  'https://github.com/ml-explore/mlx-swift-examples.git'
]

project = Xcodeproj::Project.open(PROJECT_PATH)

# Remove legacy package references and their product dependencies.
REMOVE_PACKAGE_URLS.each do |url|
  package_ref = project.root_object.package_references.find { |ref| ref.repositoryURL == url }
  next unless package_ref

  # Find and remove product dependencies tied to this package reference.
  project.targets.each do |target|
    target.package_product_dependencies.each do |pd|
      next unless pd.package == package_ref

      # Remove the build file from the Frameworks build phase.
      target.frameworks_build_phase.files.each do |build_file|
        if build_file.product_ref == pd
          build_file.remove_from_project
          break
        end
      end

      pd.remove_from_project
      puts "Removed product dependency #{pd.product_name} from #{target.name}"
    end
  end

  package_ref.remove_from_project
  puts "Removed legacy package reference: #{url}"
end

DEPENDENCIES.each do |dep|
  # 1. Create or find remote package reference
  package_ref = project.root_object.package_references.find { |ref| ref.repositoryURL == dep[:url] }
  unless package_ref
    package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
    package_ref.repositoryURL = dep[:url]
    package_ref.requirement =
      if dep[:branch]
        { 'kind' => 'branch', 'branch' => dep[:branch] }
      elsif dep[:version]
        { 'kind' => 'exactVersion', 'version' => dep[:version] }
      else
        { 'kind' => 'branch', 'branch' => 'main' }
      end
    project.root_object.package_references << package_ref
    puts "Added package reference: #{dep[:name]}"
  end

  # 2. Add product dependencies to each target
  dep[:products].each do |target_name, product_names|
    target = project.targets.find { |t| t.name == target_name }
    unless target
      warn "Target #{target_name} not found, skipping"
      next
    end

    product_names.each do |product_name|
      existing = target.package_product_dependencies.find { |pd| pd.product_name == product_name }
      if existing
        puts "  Product #{product_name} already exists on #{target_name}"
        next
      end

      product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
      product_dep.package = package_ref
      product_dep.product_name = product_name
      target.package_product_dependencies << product_dep

      # 3. Link in Frameworks build phase
      frameworks_phase = target.frameworks_build_phase
      build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
      build_file.product_ref = product_dep
      frameworks_phase.files << build_file

      puts "  Added product #{product_name} to #{target_name}"
    end
  end
end

project.save
puts "Project saved."
