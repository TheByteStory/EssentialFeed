Essential Feed

BDD Specs

Story: Customer requests to see their image feed

Narrative #1

As an online customer I want the app to automatically load my latest image feed So I can always enjoy the newest images of my friends
As an online customer
I want the app to automatically load my latest image feed
So I can always enjoy the newest images of my friends

Scenarios (Acceptance criteria)

Given the customer has connectivity
 When the customer requests to see their feed
Then the app should display the latest feed from remote
And replace the cache with the new feed
  
Narrative #2

As an offline customer I want the app to show the latest saved version of my image feed So I can always enjoy images of my friends
As an offline customer
I want the app to show the latest saved version of my image feed
So I can always enjoy images of my friends

Scenarios (Acceptance criteria)

Given the customer doesn't have connectivity
  And there’s a cached version of the feed
  And the cache is less than seven days old
 When the customer requests to see the feed
 Then the app should display the latest feed saved


Given the customer doesn't have connectivity
  And there’s a cached version of the feed
  And the cache is seven days old or more
 When the customer requests to see the feed
 Then the app should display an error message

Given the customer doesn't have connectivity
  And the cache is empty
 When the customer requests to see the feed
 Then the app should display an error message

Use Cases

Load Feed From Remote Use Case

Data:

URL
Primary course (happy path):

Execute "Load Feed Items" command with above data.
System downloads data from the URL.
System validates downloaded data.
System creates feed items from valid data.
System delivers feed items.

Invalid data – error course (sad path):

System delivers invalid data error.
No connectivity – error course (sad path):

System delivers connectivity error.
Load Feed From Cache Use Case

Data:


Primary course:

Execute "RetrieveLoad Feed Items" command with above data.
System fetches feed data from cache.

System validates cache is less than seven days old.
System creates feed items from cached data.
System delivers feed items.

Error course (sad path):

System delivers error.

Expired cache course (sad path):

System deletes cache.
System delivers no feed items.
Empty cache course (sad path):

System delivers no feed items.
Cache Feed Use Case

Data:

Feed items
Primary course (happy path):

Execute "Save Feed Items" command with above data.
System deletes old cache data.
System encodes feed items.
System timestamps the new cache.
System saves new cache data.
System delivers success message.
Deleting error course (sad path):

System delivers error.
Saving error course (sad path):


System delivers error.
