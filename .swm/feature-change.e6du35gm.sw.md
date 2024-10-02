---
title: Feature change
---
# Introduction

This document will walk you through the implementation of the flight information form feature.

The feature introduces a form for users to input their flight details.

We will cover:

1. The structure of the form.
2. The fields included in the form.
3. The rationale behind the required fields.

# Form structure

<SwmSnippet path="/app/views/calagator/site/index.html.erb" line="40">

---

The form is defined using <SwmToken path="/app/views/calagator/site/index.html.erb" pos="43:2:2" line-data="&lt;%= form_with url: flights_path, method: :post, local: true do |form| %&gt;">`form_with`</SwmToken>, which binds it to the <SwmToken path="/app/views/calagator/site/index.html.erb" pos="43:7:7" line-data="&lt;%= form_with url: flights_path, method: :post, local: true do |form| %&gt;">`flights_path`</SwmToken> URL and uses the POST method. This ensures that the form data is sent to the server for processing.

```html+erb

<h1>Flight Information Form</h1>

<%= form_with url: flights_path, method: :post, local: true do |form| %>
  <div>
    <%= form.label :name, "Full Name" %>
    <%= form.text_field :name, required: true %>
  </div>
```

---

</SwmSnippet>

# User details section

<SwmSnippet path="/app/views/calagator/site/index.html.erb" line="48">

---

We start by collecting basic user information such as full name, date of birth, and passport number. These fields are essential for identifying the user and verifying their identity.

```html+erb

  <div>
    <%= form.label :date_of_birth, "Date of Birth" %>
    <%= form.date_field :date_of_birth, required: true %>
  </div>

  <div>
    <%= form.label :passport_number, "Passport Number" %>
    <%= form.text_field :passport_number, required: true %>
  </div>
```

---

</SwmSnippet>

# Travel details section

<SwmSnippet path="/app/views/calagator/site/index.html.erb" line="58">

---

Next, we gather travel-related information including nationality, departure city, and destination city. These fields help in understanding the user's travel plans.

```html+erb

  <div>
    <%= form.label :nationality, "Nationality" %>
    <%= form.text_field :nationality, required: true %>
  </div>

  <div>
    <%= form.label :departure_city, "Departure City" %>
    <%= form.text_field :departure_city, required: true %>
  </div>
```

---

</SwmSnippet>

# Travel dates section

<SwmSnippet path="/app/views/calagator/site/index.html.erb" line="68">

---

We then collect the departure date and return date. These dates are crucial for planning and managing the user's travel itinerary.

```html+erb

  <div>
    <%= form.label :destination_city, "Destination City" %>
    <%= form.text_field :destination_city, required: true %>
  </div>

  <div>
    <%= form.label :departure_date, "Departure Date" %>
    <%= form.date_field :departure_date, required: true %>
  </div>
```

---

</SwmSnippet>

# Contact information section

<SwmSnippet path="/app/views/calagator/site/index.html.erb" line="78">

---

Finally, we ask for the user's email and phone number. This information is necessary for communication purposes.

```html+erb

  <div>
    <%= form.label :return_date, "Return Date" %>
    <%= form.date_field :return_date, required: true %>
  </div>

  <div>
    <%= form.label :email, "Email" %>
    <%= form.email_field :email, required: true %>
  </div>
```

---

</SwmSnippet>

# Form submission

<SwmSnippet path="/app/views/calagator/site/index.html.erb" line="88">

---

The form concludes with a phone number field and a submit button. The phone number is another contact method, and the submit button sends the form data to the server.

```html+erb

  <div>
    <%= form.label :phone_number, "Phone Number" %>
    <%= form.telephone_field :phone_number, required: true %>
  </div>

  <div>
    <%= form.submit "Submit" %>
  </div>
<% end %>
```

---

</SwmSnippet>

This structure ensures that all necessary information is collected in a logical and organized manner.

<SwmMeta version="3.0.0" repo-id="Z2l0aHViJTNBJTNBY2FsYWdhdG9yJTNBJTNBY2hyaXNicnVt" repo-name="calagator"><sup>Powered by [Swimm](https://app.swimm.io/)</sup></SwmMeta>
