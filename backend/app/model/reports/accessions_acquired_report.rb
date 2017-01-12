class AccessionsAcquiredReport < AbstractReport
  
  register_report({
                    :uri_suffix => "accessions_acquired",
                    :description => "Displays a list of all accessions acquired in a specified time period. Report contains accession number, title, extent, accession date, container summary, cataloged, date processed, rights transferred and the total number and physical extent.",
                    :params => [["from", Date, "The start of report range"],
                                ["to", Date, "The start of report range"]]
                  })

  def initialize(params, job)
    super
    from = params["from"] || Time.now.to_s
    to = params["to"] || Time.now.to_s
   
    @from = DateTime.parse(from).to_time.strftime("%Y-%m-%d %H:%M:%S")
    @to = DateTime.parse(to).to_time.strftime("%Y-%m-%d %H:%M:%S")
  
  end

  def title
    "Accessions acquired between #{@from} and #{@to}"
  end

  def headers
    ['accessionNumber', 'title', 'accessionDate', 'containerSummary', 'cataloged',
     'accessionProcessedDate', 'rightsTransferred', 'extentNumber', 'extentType']
  end

  def processor
    {
      'accessionNumber' => proc {|record| ASUtils.json_parse(record[:accessionNumber] || "[]").compact.join("-")},
      'accessionDate' => proc {|record| record[:accessionDate].strftime("%Y-%m-%d")},
      'cataloged' => proc {|record| record[:cataloged] == 1 },
      'rightsTransferred' => proc {|record| record[:rightsTransferred] == 1 },
      'extentNumber' => proc {|record| record[:extentNumber].to_f },
    }
  end

  def query(db)
    db["SELECT
     accession.id AS accessionId,
     accession.repo_id AS repo_id,
     accession.identifier AS accessionNumber,
     accession.title AS title,
     accession.accession_date AS accessionDate,
     GetAccessionContainerSummary(accession.id) AS containerSummary,
     GetAccessionProcessed(accession.id) AS accessionProcessed,
     GetAccessionProcessedDate(accession.id) AS accessionProcessedDate,
     GetAccessionCataloged(accession.id) AS cataloged,
     GetAccessionExtent(accession.id) AS extentNumber,
     GetAccessionExtentType(accession.id) AS extentType,
     GetAccessionRightsTransferred(accession.id) AS rightsTransferred
FROM
     accession accession
WHERE
     accession.accession_date >= ? and
     accession.accession_date <= ? ", @from, @to]
  end

end
