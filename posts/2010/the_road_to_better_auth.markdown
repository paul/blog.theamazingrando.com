Title: The Road to Better Authorization

The Problem
-----------

I have several Google accounts: My [personal email][], Google Apps at [my employer][], and Gmail for [my domain][]. I use my personal email all the time, and have several Google Docs spreadsheets and letters. Our company uses Google Docs and Sites. Its extremely annoying that switching between these accounts is brittle, and unpredictable. The same situation existed on Github between my personal and the company account, before they added "Organizations".

The other problem is poor integration with the hundreds of accounts I have across various sites. I have a simple password that I use for throwaway, which is still horribly insecure. The alternative is a password manager such as KeePass or 1Password, but browser integration is poor or non-existent.

I use the [Google Mail Checker Plus][GMCP] extension for Chrome, which can automatically redirect me to the Gmail inbox for each account, and from there I can follow links to Docs or Sites. However, all the accounts are "logged in", and I occasionally experience trouble and get permission denied errors when I click on a document link in my list.

My main workaround at this point is to use Chrome for normal browsing and personal accounts, and Firefox, which I use for development & debugging anyways, has the saved passwords for company accounts. This has worked for awhile, but as I amass various side-projects, and need a 3rd login for some sites (Github and Amazon AWS seem to be the main ones), I don't want to have to maintain more browser profiles.

Ideally, the browser and sites would integrate and work together to manage everything automatically, but this is a chicken and egg problem. The solution will likely have to be completed in stages.

OpenID and OAuth are attempts at solving this on the server side, but they are complicated. And they need to be, because there's several parties involved, all needing to handshake with each other and prove everyone's identity. I feel a simpler solution, and a much better way to handle this, would be in the browser itself. Even the technical name for the browser, "User Agent", indicates its purpose. I see it as the concierge at an expensive hotel. They have the inside knowledge of the city, and the personal contacts, to get you anything you need. Want blueberry and peanut-butter waffles at 11pm? Call the concierge and he'll figure out how to get it for you.

Same for the browser. It's your concierge for the web. You don't need to know HTML and CSS to be able to use a website, the browser renders the text and images into a sensible layout for you to read. If a page moved, you don't have to type in the new location manually, the browser automatically goes there for you. If you need credentials to visit your Facebook page, you don't have to deal with the ugly bouncer directly, the concierge coughs and politely asks you for your password. What I'm proposing is promoting your concierge to your own personal assistant. You shouldn't even need to know there *is* a bouncer, because your assistant has already made arrangements and you can walk right in.

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

There's also programs such as [KeePassX][], [1Password][], and [LastPass][], some of which include browser plugins that can manage passwords for you. These all seem to be standalone password managers first, with the browser integration coming 2nd, which can sometimes be pretty clunky. Phase one needs to be a browser extension specifically designed to integrate with web site logins.

Phase 2
-------

The next phase would be for the browser to be able to manage account creation. Since the browser can manage my accounts, it would be handy if it would create them, by automatically filling out the sign up form at the site. Browsers already have my name, email, address, etc, from being able to auto-fill forms. It could auto-fill the sign up form with my personal information (or suitably anonymized information if I choose), create a login and a random password, and save all that with the account manager.

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

Since names like `"reg_email__"` are rather nonstandard, we'll need some way to map the fields we know for our profile to the fields on the website form. The mappings are probably too complicated to be one-to-one with a simple XML or JSON file, however a JavaScript function could be executed:

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

    <script>
      accountManager.setSignup(function(profile) { ... } );
    </script>

Where `setSignup` is the browser API function to call to assign your website's signup function, and `profile` is an object containing the personal information provided by the user.

Phase 3
-------

Phase 3 involves developing an API between the browser and the web page directly. It can be a simple extension to some of the new HTML5 APIs out there for dealing with video or local storage in javascript. Hopefully (but not likely, given how similar projects have played out before), each browser that implements this would have a similar API that common elements could be used.


Conclusion
----------

In conclusion, authentication for web services sucks, and has for a long time. The right place to manage this is in the browser itself, rather than a complicated handshaking protocol between servers. Writing a browser extension like the one described in Phase 1 is on my TODO list, but I know nothing about browser extensions, and have plenty of other projects to keep me busy. If someone out there is willing to take this on, drop me a line, I'd certainly love to help.

Extra Credit
------------

 * Store all the data in the cloud, so its not lost in reformats, and can be shared between computers. Even better, have an interchange format so it can be shared between browsers, and your phone, so you can login to sites from wherever.
 * An extension to the built-in HTTP Auth methods, something more secure than the MD5 used in Digest Auth. Properly implemented with nonces and cnonces, Digest Auth is still pretty secure, but it will only be a matter of time before MD5 can be brute-forced in a reasonable amount of time. Or maybe just convince everyone that all HTTP should be over SSL, and then we can just use Basic Auth. Once people start using browser authentication managers, no-one will care about styling the login form any more. Maybe the browser could load the favicon, or follow a `<link>` tag to a logo image for the site being logged in to.




[personal email]:          mailto:psadauskas@gmail.com
[my employer]:             http://absolute-performance.com
[my domain]:               http://theamazingrando.com
[GMCP]:                    http://chrome.desc.se/
[Account Manager]:         https://wiki.mozilla.org/Labs/Weave/Identity/Account_Manager
[KeePassX]:                http://www.keepassx.org/
[1Password]:               http://agilewebsolutions.com/onepassword
[LastPass]:                https://lastpass.com/

