# -*- coding: utf-8 -*-

module OrfeoImporter

  ##
  # Very simple class for collecting statistics.
  class Stat
    attr :stats
    attr :title

    def initialize(title = 'Statistics')
      @stats = {}
      @total = 0
      @title = title
    end

    def add(key)
      @stats[key] = 0 unless @stats.key? key
      @stats[key] += 1
      @total += 1
    end

    def empty?
      return true if @total == 0
      false
    end

    def show
      puts "--- #{title} ---"
      @stats.each do |key, num|
        puts "  #{key}: #{num} (%.1f%%)" % (100.0*num/@total)
      end
      puts
    end
  end
end
