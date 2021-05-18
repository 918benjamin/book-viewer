require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do

  def in_paragraphs(text)
    text.split("\n\n").map.with_index do |paragraph, index|
      "<p id=paragraph#{index}>#{paragraph}</p>"
    end.join
  end

  def highlight_query(text, term)
    # text.split(params[:query]).join("<strong>#{params[:query]}</strong>")
    text.gsub(term, "<strong>#{term}</strong>")
  end

end

not_found do
  redirect "/"
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do |n|
  number = n.to_i

  redirect "/" unless (1..@contents.size).cover?(number)

  @title = "Chapter #{number} - #{@contents[number - 1]}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

def each_paragraph(chapter, query)
  paragraphs = {}
  chapter.split("\n\n").each_with_index do |paragraph, index|
    paragraphs[index] = paragraph if paragraph.include?(query)
  end
  paragraphs
end

def chapters_matching(query)
  results = []

  return results if !query || query.empty?

  each_chapter do |number, name, contents|
    if contents.include?(query)
      results << {number: number, name: name} 
      results[-1][:paragraphs] = each_paragraph(contents, query)
    end
  end

  results
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end