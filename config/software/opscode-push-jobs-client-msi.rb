#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name "opscode-push-jobs-client-msi"

source :path => File.expand_path("files/msi", Omnibus.project_root)

build do

  package_name = "opscode-push-jobs-client"

  # harvest with heat.exe
  # recursively generate fragment for opscode-push-jobs-client directory
  block do
    src_dir = self.project_dir

    shell = Mixlib::ShellOut.new("heat.exe dir \"#{install_dir}\" -nologo -srd -gg -cg PushyClientDir -dr PUSHYLOCATION -var var.PushyClientSourceDir -out opscode-push-jobs-client-Files.wxs", :cwd => src_dir)
    shell.run_command
    shell.error!
  end

  # Prepare the include file which contains the version numbers
  block do
    require 'erb'

    File.open("#{project_dir}\\templates\\#{package_name}-Config.wxi.erb") { |file|
      # build_version looks something like this:
      # dev builds => 0.10.8-299-g360818f
      # pre builds => 1.0.0.rc.1+20130920214917.git.4.4646657
      # rel builds => 0.10.8-299
      numeric_version = build_version.split("+").first
      versions = numeric_version.split("-").first.split(".")
      @major_version = versions[0]
      @minor_version = versions[1]
      @micro_version = versions[2]
      @build_version = self.project.build_iteration

      # Find path to which the opscode-pushy-client gem is installed.
      # Note that install_dir is something like:
      # c:\opscode\pushy
      push_jobs_path_regex = "#{install_dir.gsub(File::ALT_SEPARATOR, File::SEPARATOR)}/**/gems/opscode-pushy-client*"
      @push_jobs_gem_path = Dir[push_jobs_path_regex].select{ |path| File.directory?(path) }.first
      raise "Can not find installation directory for opscode-pushy-client gem using: #{push_jobs_path_regex}" unless @push_jobs_gem_path

      # Convert the opscode-pushy-client gem path to a relative path based on install_dir
      # We are going to use this path in the startup command of the push-jobs
      # service. So we need to change file separators to make windows
      # happy.
      @push_jobs_gem_path.gsub!(File::SEPARATOR, File::ALT_SEPARATOR)
      @push_jobs_gem_path.slice!(install_dir.gsub(File::SEPARATOR, File::ALT_SEPARATOR) + File::ALT_SEPARATOR)

      @guid = "D607A85C-BDFA-4F08-83ED-2ECB4DCD6BC5"

      erb = ERB.new(file.read)
      File.open("#{project_dir}\\#{package_name}-Config.wxi", "w") { |out|
        out.write(erb.result(binding))
      }
    }
  end

  install_dir_native = install_dir.split(File::SEPARATOR).join(File::ALT_SEPARATOR)

  # Create temporary directory to store the files required for msi
  # packaging.
  command "IF exist #{install_dir_native}\\msi-tmp (echo msi-tmp is found on the system) ELSE (mkdir #{install_dir_native}\\msi-tmp && echo msi-tmp directory is created.) "

  # Copy the localization file into the temporary file directory for packaging
  command "xcopy opscode-push-jobs-client-en-us.wxl #{install_dir_native}\\msi-tmp /Y", :cwd => source[:path]

  # Copy the asset files into the temporary file directory for packaging
  command "xcopy assets #{install_dir_native}\\msi-tmp\\assets /I /Y", :cwd => source[:path]

  # compile with candle.exe
  block do
    src_dir = self.project_dir

    shell = Mixlib::ShellOut.new("candle.exe -nologo -out #{install_dir_native}\\msi-tmp\\ -dPushyClientSourceDir=\"#{install_dir_native}\" opscode-push-jobs-client-Files.wxs opscode-push-jobs-client.wxs", :cwd => src_dir)
    shell.run_command
    shell.error!
  end
end