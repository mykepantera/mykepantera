#!/usr/bin/env ruby

require 'fileutils'

ESCAPE_CHAR = '"'
SPLIT_CHAR = ','
NL = "\n"
TEMPLATE = "mech_template.html"

class HTMLTableWriter

  def initialize
    clear
    
    if File.file?(TEMPLATE)
      @template = File.read(TEMPLATE)
    end
  end
  
  def startTable(name)
    @title = name
    @table << @indent << '<table>' << NL
    @indent << "  "
    @sarna.gsub!('Main_Page', @title.gsub(' ', '%20'))
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
      @table << @indent << '<td>' << formatContent(content) << '</td>' << NL
    end
  end
  
  def addHeader(content)
    @table << @indent << '<th>' << content << '</th>' << NL
  end
  
  def image=(image)
    @image = image
  end
  
  def sarna=(source)
    @sarna = source
  end
  
  def clear
    @title = ""
    @table = ""
    @indent = ""
    @image = nil
    @sarna = "http://www.sarna.net/wiki/Main_Page"
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
      content.gsub!(/@sarna@/, @sarna)
    end
    File.write(filename, content)
    
    if clear 
      clear()
    end
  end
  
  private
  
  def formatContent(content)
    if content.include?('(')
      content.gsub!('(', '<span class="fixed">(')
      content.gsub!(')', ')</span>')
    end
    if content.include?('*')
      content.gsub!('*').with_index(1) {|_,i| i.odd? ? '<span class="fixed">' : '</span>'}
    end
    return content
  end
  
end

begin
  if ARGV.length == 0
    puts "cvstohtml.rb <filename>"
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
  overview = false
  while (line = lights.gets)
    combined = 0
    line.chomp.split(SPLIT_CHAR, -1).each_with_index do |cell, i|
      # combine split cell
      escaped = cell.include?(ESCAPE_CHAR)
      if escaped and multicell.nil?
        multicell = cell.sub(ESCAPE_CHAR, '')
        next
      elsif escaped
        multicell.concat(SPLIT_CHAR).concat(cell.sub(ESCAPE_CHAR, ''))
        cell = multicell
        multicell = nil
        combined += 1
      elsif !multicell.nil?
        multicell.concat(SPLIT_CHAR).concat(cell)
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
            overview = true
            next
          elsif overview 
            if i == 2 && cell.downcase.end_with?("jpg") or cell.end_with?("png") or cell.end_with?("gif")
              generator.image = cell
            elsif i == 3 && !cell.empty?
              generator.sarna = cell
              break
            end
          else
            generator.addCell(cell)
          end
        end
      end
    end
    
    if content > 0
      generator.endRow
    end
    overview = false
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
