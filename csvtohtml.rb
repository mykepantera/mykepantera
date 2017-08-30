#!/usr/bin/env ruby

require 'fileutils'

ESCAPE_CHAR = '"'
SPLIT_CHAR = ','
NL = "\n"
TEMPLATE = "mech_template.html"

class HTMLTableWriter

  def initialize
    @title = ""
    @table = ""
    @indent = ""
    @table = ""
    @image = nil
    
    if File.file?(TEMPLATE)
      @template = File.read(TEMPLATE)
    end
  end
  
  def startTable(name)
    @title = name
    @table << @indent << '<table>' << NL
    @indent << "  "
  end
  
  def endTable
    @table << @indent.chomp!("  ") << '</table>' << NL
  end
  
  def startRow
    @table << @indent << '<tr>' << NL
    @indent << "  "
  end
  
  def endRow
    @table << @indent.chomp!("  ") << '</tr>' << NL
  end
  
  def addCell(content, colspan=1)
    if colspan > 1
      @table << @indent << "<td colspan=\"#{colspan}\"><span class=\"headline\">" << content << '</span></td>' << NL
    else
      @table << @indent << '<td>' << content << '</td>' << NL
    end
  end
  
  def addHeader(content)
    @table << @indent << '<th>' << content << '</th>' << NL
  end
  
  def image=(image)
    @image = image
  end
  
  def clear
    @indent = ""
    @table = ""
  end
  
  def print(path, clear)
    if !path.nil? and !File.directory?("./#{path}")
      puts "mkdir #{path}"  
      FileUtils.mkdir(path)
    end

    filename = "#{path}/#{@title}.html"
    puts "Writing mech data #{filename}"
    content = ""
    if @template.nil? 
      content = @table
    else
      content = @template.gsub(/@title@/, @title)
      content.gsub!(/@table@/, @table)
      if !@image.nil?
        content.gsub!(/@image@/, @image)
      end
    end
    File.write(filename, content)
    
    if clear 
      clear()
    end
  end
end

begin
  if ARGV.length == 0
    puts "cvstobbcode.rb <filename>"
    exit
  end
  if ! File.file? ARGV[0]
    puts "#{ARGV[0]} not a file"
    exit
  end
  puts "Creating html pages for #{ARGV[0]}"
  lights = File.new(ARGV[0], "r")
  generator = HTMLTableWriter.new

  content = 0
  columns = 0
  multicell = nil
  path = nil
  while (line = lights.gets)
    combined = 0
    line.chomp.split(SPLIT_CHAR, -1).each_with_index do |cell, i|
      
      # combine split cell
      escaped = cell.include?(ESCAPE_CHAR)
      if escaped and multicell.nil?
        multicell = cell.sub(ESCAPE_CHAR, '')
        next
      elsif escaped
        multicell = multicell.concat(SPLIT_CHAR, cell.sub(ESCAPE_CHAR, ''))
        cell = multicell
        multicell = nil
        combined += 1
      elsif !multicell.nil?
        multicell = multicell.concat(SPLIT_CHAR, cell)
        combined += 1
        next
      end
      
      if i > 0
        if i == 1
          if cell.empty?
            if content > 1
              generator.endTable
              generator.print(path, true)
            elsif content > 0
              generator.clear
            end
            content = 0
            break
          end
          
          if content == 0
            if path.nil?
              path = cell
            end
            generator.startTable(cell)
            columns = 1
          end
          generator.startRow
          
          content += 1
        end
        
        if content == 1
          if cell.empty?
            break
          end
          i == 1 ? generator.addHeader("") : generator.addHeader(cell)
          columns += 1
        elsif i < columns + combined
          if cell.start_with?("Weapons") or cell.start_with?("Hardpoints") or cell.start_with?("Omnipods")
            generator.addCell(cell, columns - 1)
            break
          elsif cell.start_with?("Overview")
            generator.addCell(cell, columns - 1)
          elsif cell.end_with?("jpg") or cell.end_with?("png")
            generator.image = cell
            break
          else
            generator.addCell(cell)
          end
        end
      end
    end
    
    if content > 0
      generator.endRow
    end
  end
  if content > 1
    generator.endTable
    generator.print(path, true)
  end
  lights.close
rescue Exception => err
  puts "Exception: #{err}"
  err
end