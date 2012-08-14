module WebBlocks
  
  class Compiler
    
    attr_accessor :src, :mods, :adapter, :sass_dir, :img_dir, :js_core_dir, :js_core_ie_dir, :js_scripts_dir, :dst
    
    def initialize config, dst
      
      @src = config[:dir]
      @mods = config[:modules]
      @adapter = config[:adapter]
      @sass_dir = config[:sass]
      @img_dir = config[:img]
      @js_core_dir = config[:js][:core]
      @js_core_ie_dir = config[:js][:core_ie]
      @js_script_dir = config[:js][:script_dir]
      @dst = dst
      
    end
    
    def ext? file, ext
      ext = ext.join '|' if ext.respond_to? 'join'
      file.match(/.*\.(#{ext})$/)
    end
    
    def scss? file
      ext? file, 'scss'
    end
    
    def js? file
      ext? file, 'js'
    end
    
    def img? file
      ext? file, ['jpg', 'jpeg', 'gif', 'png', 'bmp', 'tif', 'svg']
    end
    
    def generate
      
      pwd = Dir.pwd
      Dir.chdir @src
      
      FileUtils.rm_rf "tmp" if File.exists? "tmp";
      mkdir "tmp";
      
      scss = File.open "tmp/_WebBlocks.scss", "w"
      js = File.open "../#{@dst}/js/blocks.js", "a"
      js_ie = File.open "../#{@dst}/js/blocks-ie.js", "a"
      scss.puts "@import \"variables\";"
      
      @mods.unshift "adapter/#{@adapter}"
      @mods.each do |mod|
        tree = get_tree mod
        tree.flatten.each do |file|
          case
          when scss?(file)
            puts "[WebBlocks::Compiler mod scss] #{file}"
            file.chomp! ".scss";
            scss.puts "@import \"#{file}\";"
          when js?(file)
            puts "[WebBlocks::Compiler mod js core] #{file}"
            contents = File.read(file)
            js.puts contents
          when img?(file)
            puts "[WebBlocks::Compiler mod img] #{file}"
            dst = @dst[0,1] == '/' ? "#{@dst}/img/#{file}" :"../#{@dst}/img/#{file}"
            cp_mkdir file, dst
          end
        end
      end
      
      tree = get_tree @img_dir
      tree.flatten.each do |file|
        relfile = file.gsub /^#{@img_dir}\//, ""
        puts "[WebBlocks::Compiler app img] #{relfile}"
        dst = @dst[0,1] == '/' ? "#{@dst}/img/#{relfile}" : "../#{@dst}/img/#{relfile}"
        cp_mkdir file, dst
      end
      
      tree = get_tree @js_core_dir
      tree.flatten.each do |file|
        puts "[WebBlocks::Compiler app js core] #{file}"
        contents = File.read(file)
        js.puts contents
      end
      
      tree = get_tree @js_core_ie_dir
      tree.flatten.each do |file|
        puts "[WebBlocks::Compiler app js core-ie] #{file}"
        contents = File.read(file)
        js_ie.puts contents
      end
      
      tree = get_tree @js_script_dir
      tree.flatten.each do |file|
        relfile = file.gsub /^#{@js_script_dir}\//, ""
        puts "[WebBlocks::Compiler app js script] #{relfile}"
        dst = @dst[0,1] == '/' ? "#{@dst}/js/script/#{relfile}" : "../#{@dst}/js/script/#{relfile}"
        cp_mkdir file, dst
      end
      
      scss.close
      js.close
      js_ie.close
      
      puts "compass compile --sass-dir #{@sass_dir} --css-dir ../#{@dst}/css" 
      sh "compass compile --sass-dir #{@sass_dir} --css-dir ../#{@dst}/css" 
      
      FileUtils.rm_rf "tmp" if File.exists? "tmp";
      
      Dir.chdir pwd
      
    end
    
    def get_tree path
      
      contents = []
      
      contents.push path if File.file? path
      
      dir = File.dirname path
      Dir.entries(dir).each do |child|
        contents.push "#{dir}/#{child}" if child.match(/^_?(#{File.basename path})\..*/)
      end

      return contents unless FileTest.directory? path
      
      Dir.entries(path).each do |child|
        contents.push get_tree "#{path}/#{child}" unless child[0,1] == '.'
      end
      
      return contents
      
    end
    
    def cp_mkdir src, dst
      FileUtils.mkdir_p(File.dirname(dst))
      FileUtils.cp src, dst
    end
    
    def execute
      
      self.generate
      
    end
    
  end
  
end