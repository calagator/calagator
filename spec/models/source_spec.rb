require File.dirname(__FILE__) + '/../spec_helper'

describe Source do
  before(:each) do
    @source = Source.new
  end

  it "should parse hcal" do
    hcal_content = <<-HERE# {{{
<-- ADD CLASS="VEVENT" TO PAGE BODY-->


<body  class ="vevent" vlink="#666666" text="#ffffff" marginwidth="0" marginheight="0" link="#cccccc" bgcolor="#000000" alink="#999999" onload="preloadImages();" topmargin="0" leftmargin="0">

 

<...>


<-- ADD CLASS ="SUMMARY"-->

<td id="contentText" width="50%" valign="top" align="left">
<h2>MEETING INFORMATION :</h2>

<p>
<br/>
<div class="summary">Portland Final Cut User Group now meets on the first Tuesday of every month from 6:30-8:30 PM.</div>
<br/>
<br/>
The location is:
<br/>
<font face="Arial, Helvetica, sans-serif">
<-- ADD CLASS ="LOCATION"-->
<span class="location">PCC/Cascade Campus
<br/>
705 N. Killingsworth St. (x Albina)
<br/>
Moriarty Arts and Humanities Building, Room 104.</span>
<br/>
<-- ADD CLASS ="URL"-->
<span class="url">Link:
<a target="_blank" href="http://www.pcc.edu/about/locations/cascade/">www.pcc.edu/about/locations/cascade/ </a></span>
</font>
<br/>
<br/>
</p>
 
<...>

<td id="contentText" width="50%">
<-- ADD CLASS ="DTSTART"-->
<h2 class="dtstart">Tuesday December 04, 2007 6:15pm AGENDA:</h2>
<table>
<tbody>
<tr>
<td height="20">6:15 - 6:30</td>
    HERE
# }}}

    final_cut_hcal = Source.new(:title => "Final Cut User Group", :url => "FIXME", :format_type => "hcal")

    final_cut_hcal.parse.should == [
      Event.new(:title => nil, :description => nil, :start_time => nil, :url => nil, :venue => nil) # TODO write what this is expected to create
    ]

  end
end
