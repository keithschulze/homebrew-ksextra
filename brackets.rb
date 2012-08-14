require 'formula'

class BracketsDownloadStrategy < GitDownloadStrategy
  def initialize name, package
    super
    @brackets = @clone+'brackets'
  end

  def stage
    dst = Dir.getwd
    Dir.chdir @clone do
      if @spec and @ref
        ohai "Checking out #{@spec} #{@ref}"
        case @spec
        when :branch
          nostdout { quiet_safe_system 'git', 'checkout', "origin/#{@ref}", '--' }
        when :tag, :revision
          nostdout { quiet_safe_system 'git', 'checkout', @ref, '--' }
        end
      else
        # otherwise the checkout-index won't checkout HEAD
        # https://github.com/mxcl/homebrew/issues/7124
        # must specify origin/HEAD, otherwise it resets to the current local HEAD
        quiet_safe_system "git", "reset", "--hard", "origin/HEAD"
      end
      # http://stackoverflow.com/questions/160608/how-to-do-a-git-export-like-svn-export
      safe_system 'git', 'checkout-index', '-a', '-f', "--prefix=#{dst}/"
      # check for submodules
      if File.exist?('.gitmodules')
        safe_system 'git', 'submodule', 'init'
        safe_system 'git', 'submodule', 'update'
        sub_cmd = "git checkout-index -a -f \"--prefix=#{dst}/$path/\""
        safe_system 'git', 'submodule', '--quiet', 'foreach', '--recursive', sub_cmd
      end
      Dir.chdir @brackets do
        safe_system 'git', 'submodule', 'init'
        safe_system 'git', 'submodule', 'update'
        sub_cmd = "git checkout-index -a -f \"--prefix=#{dst}/brackets/$path/\""
        safe_system 'git', 'submodule', '--quiet', 'foreach', '--recursive', sub_cmd
      end
    end
  end
end

class Brackets < Formula
  homepage 'http://brackets.io/'
  head 'git://github.com/adobe/brackets-app.git', :using => BracketsDownloadStrategy

  def install
    prefix.install Dir['*']
    prefix.install_symlink prefix+'bin/mac/Brackets.app'
  end

  def caveats; <<-EOS.undent
    DartEditor.app was installed in:
      #{prefix}

    To symlink into ~/Applications, you can do:
      brew linkapps
    EOS
  end
end
