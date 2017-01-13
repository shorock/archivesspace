class AccessionsCatalogedReport < AbstractReport

  register_report({
                    :uri_suffix => "accessions_cataloged_report",
                    :description => "Displays only those accessions that have been cataloged. Report contains accession number, linked resources, title, extent, cataloged, date processed, a count of the number of records selected that are checked as cataloged, and the total extent number for those records cataloged.",
                  })

  def title
    "Cataloged Accessions"
  end

  def template
    'accessions_cataloged_report.erb'
  end

  def processor
    {
      'accessionId' => proc {|record| record[:accessionId]},
      'repo' => proc {|record| record[:repo]},
      'accessionNumber' => proc {|record|record[:accessionNumber]},
      'title' => proc {|record| record[:title]},
      'accessionDate' => proc {|record| record[:accessionDate]},
      'accessionProcessed' => proc {|record| record[:accessionProcessed]},
      'accessionProcessedDate' => proc {|record| record[:accessionProcessedDate]},
      'cataloged' => proc {|record| record[:cataloged]},
      'catalogedDate' => proc {|record| record[:catalogedDate]},
      'extentNumber' => proc {|record| record[:extentNumber]},
      'extentType' => proc {|record| record[:extentType]},
    }
  end


  def query
    db[:accession].
      select(Sequel.as(:id, :accessionId), 
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:identifier, :accessionNumber),
             Sequel.as(:title, :title),
             Sequel.as(:accession_date, :accessionDate),
             Sequel.as(Sequel.lit('GetAccessionProcessed(id)'), :accessionProcessed),
             Sequel.as(Sequel.lit('GetAccessionProcessedDate(id)'), :accessionProcessedDate),
             Sequel.as(Sequel.lit('GetAccessionCataloged(id)'), :cataloged),
             Sequel.as(Sequel.lit('GetAccessionCatalogedDate(id)'), :catalogedDate),
             Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extentNumber),
             Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extentType))
  end


  # TODO: subreport for linked resources

  # Number of Records Reviewed
  def total_count
    @totalCount ||= self.query.count
  end

  # Cataloged Accessions
  def cataloged_count
    @catalogedCount ||= db.from(self.query).where(:cataloged => 1).count
  end

  # Total Extent of Cataloged Accessions
  def total_extent
    @totalExtent ||= db.from(self.query).where(:cataloged => 1).sum(:extentNumber)
  end
end
