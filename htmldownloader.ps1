#Configuration
##Target link to download files from
$Uri = "https://sleuthkit.org/autopsy/docs/user-docs/4.19.3"
##Folder to store files in
$DestinationFolder = ""



#If recursive is set to true it will search for links as far as it can go
$recursive=$true

#How many layers of links you want to search/download
$depth = 1

#Set to $true to silence console output
$silent = $false
#--------------------------------------------------------------------------------------------------


#Creates files for storing the links
New-Item -Path $DestinationFolder -Name "hrefs.txt" -ErrorAction SilentlyContinue
New-Item -Path $DestinationFolder -Name "searched.txt" -ErrorAction SilentlyContinue
"test" >> "$DestinationFolder\searched.txt"

#Gets links from target pages, adds it to hrefs.txt
if($silent -eq $false){Write-Host "Searching $Uri"}
(Invoke-Webrequest -Uri $Uri).Links.href | where{$_ -match "^\w" -and $_ -match "html$"} >> "$DestinationFolder/hrefs.txt"



#Function:  Searches hrefs in hrefs.txt if they are not contained in searched.txt.  After being searched it gets added to searched.txt.
function Search-href()
{
  $hrefcontent = (Get-Content "$DestinationFolder/hrefs.txt")
  foreach($href in $hrefcontent)
  {
    if((Get-Content "$DestinationFolder/searched.txt").Contains($href) -eq $false)
    {
      if($silent -eq $false){Write-Host "Searching $Uri/$href"}
      $href >> "$DestinationFolder/searched.txt"
      (Invoke-Webrequest -Uri "$Uri/$href").Links.href | where{$_ -match "^\w" -and $_ -match "html^" -and (Get-Content "$DestinationFolder\hrefs.txt").Contains($_) -eq $false}
    }
  }


}


if($recursive -eq $true)
{
  $presearch = (Get-Content "$DestinationFolder/searched.txt").count
  $postsearch = "Eggplant"
  while($presearch -ne $postsearch)
  {
    $presearch = (Get-Content "$DestinationFolder/searched.txt").count
    Search-href
    $postsearch = (Get-Content "$DestinationFolder/searched.txt").count
  }
} else
{
  for($i=0; $i -lt 3; $i +=1)
  {
    Search-href
  }
}



#Downloads files and images to $DestinationFolder
foreach($href in (Get-Content "$DestinationFolder\hrefs.txt"))
{
  $webrequest = (Invoke-Webrequest -Uri "$Uri/$href")
  if($silent -eq $false){Write-Host "Downloading $href from $Uri/$href"}
  New-Item "$DestinationFolder\$href" -Force | Out-Null
  $webrequest.RawContent >> "$DestinationFolder\$href"
  foreach($image in $webrequest.images.src)
  {
    ###I don't get paid enough to go backwards in the directory, only forward.
    if($image -notmatch "^\.")
    {
      if($silent -eq $false){Write-Host "Downloading $image from $Uri/$image"}
      New-Item "$DestinationFolder\$image" -Force | Out-Null
      Invoke-Webrequest -Uri "$Uri/$image" -Outfile "$DestinationFolder\$image"
    }
  }
}
