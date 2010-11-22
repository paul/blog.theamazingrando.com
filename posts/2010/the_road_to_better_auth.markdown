Title: The Road to Better Authorization

The Problem
-----------

I have several Google accounts: My [personal email][], Google Apps at [my employer][], and Gmail for [my domain][]. I use my personal email all the time, and have several Google Docs spreadsheets and letters. Our company uses Google Docs and Sites. Its extremely annoying that switching between these accounts is brittle, and unpredictable. The same situation existed on Github between my personal and the company account, before they added "Organizations".

The other problem is poor integration with the hundreds of accounts I have across various sites. I have a simple password that I use for throwaway, which is still horribly insecure. The alternative is a password manager such as KeePass or 1Password, but browser integration is poor or non-existent.

I use the [Google Mail Checker Plus][GMCP] extension for Chrome, which can automatically redirect me to the Gmail inbox for each account, and from there I can follow links to Docs or Sites. However, all the accounts are "logged in", and I occasionally experience trouble and get permission denied errors when I click on a document link in my list.

My main workaround at this point is to use Chrome for normal browsing and personal accounts, and Firefox, which I use for development & debugging anyways, has the saved passwords for company accounts. This has worked for awhile, but as I amass various side-projects, and need a 3rd login for some sites (Github and Amazon AWS seem to be the main ones), I don't want to have to maintain more browser profiles.

Ideally, the browser and sites would integrate and work together to manage everything automatically, but this is a chicken and egg problem. The solution will likely have to be completed in stages.

Phase 1
-------

The first step is a browser extension for managing all my accounts at various sites. On a site where I have several accounts, or a personal account and a shared corporate account, it would be great to have a simple way to switch between them. When I come to a page, but want to view it as a different account, I have to:

 1. Find and click a "Sign Out" link.
 2. Find the "Sign In" link.
 3. Clear the "username" field of the form, and replace it with the other account's username.
 4. Hope the browser remembers the other account's password, or look it up and fill it in.
 5. Navigate back to the original page.

Compare that to a browser extension or built-in feature:

 1. Click "Account Manager" toolbar button, which provides a list of known accounts for the site.
 2. Select the account from the list.

The implementation would be straightforward. Just save all the cookies currently associated with the domain and tie them to that account, then load the previously stored cookies for the account that was selected, and re-request the page with the new cookies. If the page is using http authentication, the browser only has to change which Authorization header it is providing to the site.

There have been various attempts to do this, but nothing ever seems completed. I haven't attempted my own, so maybe there's some complication that I'm missing. Mozilla has a proposal for such an extension called [Account Manager][], but there seems to be no real activity since a few weeks after the project was announced back in March 2010. This seems like a real win for users, I can't understand why no browser has this built-in, or even an extension. I'd switch to Opera or Safari in a minute if they offered this, its a killer feature for a browser.

Phase 2
-------

The next phase would be for the browser to be able to manage account creation, as well. Since the browser can manage my accounts, it would be handy if it would create them, by automatically filling out the sign up form at the site. Browsers already have my name, email, address, etc, from being able to auto-fill forms. It could auto-fill the sign up form with my personal information, or possibly anonymized information if I choose. Create a login, and a random password, with a confirmation if necessary, and save all that with the account manager.

Undoubtedly, this would require "rules" for lots of sites, similar to adblock extensions, to know which signup fields are which, and how exactly to fill out the signup form. Perhaps some JSON to indicate field names, or even some javascript.

For example, say we have a signup form (like, say, Facebook's, with non-essential tags stripped out):

    <form method="post" id="reg" name="reg">
      <input type="text" class="inputtext" id="firstname" name="firstname">
      <input type="text" class="inputtext" id="lastname" name="lastname">
      <input type="text" class="inputtext" id="reg_email__" name="reg_email__">
      <input type="text" class="inputtext" id="reg_email_confirmation__" name="reg_email_confirmation__">
      <input type="password" class="inputtext" id="reg_passwd__" name="reg_passwd__" value="">
      <select class="select" name="sex" id="sex"><option value="1">Female<option value="2">Male</select>
      <select id="birthday_month" name="birthday_month">...</select>
      <select name="birthday_day" id="birthday_day">...</select>
      <select name="birthday_year" id="birthday_year">...</select>
      <input value="Sign Up" type="submit">
    </form>

Since names like `"reg_email__"` are rather nonstandard, we'll need some way to map the fields we know for our profile to the fields on the website form. The mappings are probably to complicated to be one-to-one with a simple XML or JSON file, however a JavaScript function to be executed:

    function performSignup(profile) {
      $("#firstname").val(profile.first_name);
      $("#lastname").val(profile.last_name);
      $("#reg_email__").val(profile.email);
      $("#reg_email_confirmation__").val(profile.email);
      $("#reg_passwd__").val(profile.generate_random_password());
      $("#sex").val(profile.gender == "male" ? "2" : "1");
      $("#birthday_day").val(profile.birthday.day);
      $("#birthday_month").val(profile.birthday.month);
      $("#birthday_year").val(profile.birthday.year);

      $("#reg").submit();
    }

Some helpers to make that less verbose, and getting contributions to write rules for the most common sites, and now your browser can perform signups for you. If this becomes popular or compelling to websites to implement, a JavaScript browser API could be exposed so that websites could implement the signup function themselves.

    accountManager.setSignup(function(profile) { ... } );

Where `setSignup` is the browser API function to call to assign your website's signup function, and `profile` is an object containing the personal information provided by the user.




Extra Credit
------------

 * Store all the data in the cloud, so its not lost in reformats, and can be shared between computers. Even better, have an interchange formate so it can be shared between browsers, and your phone, so you can login to sites from wherever.




[personal email]:          mailto:psadauskas@gmail.com
[my employer]:             http://absolute-performance.com
[my domain]:               http://theamazingrando.com
[GMCP]:                    http://chrome.desc.se/
[Account Manager]:         https://wiki.mozilla.org/Labs/Weave/Identity/Account_Manager

