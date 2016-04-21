
# Let's Encrypt + Route53 + Ruby = Yay!

A few months ago, Let's Encrypt [rolled out a feature to verify domains over
DNS][DNS challenges]. Their automatic configuration tool doesn't support all
the use cases yet, including my particular scenario: multiple load-balanced EC2
instances behind a single ELB, using Route53 for DNS. I [wrote a
tool][letsencrypt-route53] to simplify updating Route53 DNS Records with the
challenge, as well as updating the ELB with the resulting certificate. Check
out the [README][letsencrypt-route53] and [code][letsencrypt-route53], or read
on for why I wrote it.

Previously, the way to prove you owned a particular domain was to have a web
server host a file that Lets Encrypt provided, which they would then query and
confirm the results. This works great, and they even provide a client that will
automagically configure your nginx or apache webserver to host the file. Having
a magic tool touch my webserver config makes me nervous, however. Additionally,
I have multiple web servers behind an ELB load balancer, and it was not clear
to me how that update would work, since all the servers would have to have the
same file in the same location at the same time, lest the Lets Encrypt
verification check get routed to a server that didn't have it. I'm sure they've
thought of this, but that many moving parts behind a magic tool made me
concerned for potential downtime.

However, the DNS challenge gets around the load-balanced web server problem by letting you set the challenge as a `TXT` record on the DNS server hosting your domain. The tool I've written which automates this process also takes care of a lot of the other steps needed to update your ELB and clean up after itself.

## Let's Encrypt DNS Challenges

These are the steps needed to obtain a certificate from Let's Encrypt, and update your ELB with it:


1. Tell LetsEncrypt.org that you'd like to protect the domain at
   `myawesomeblog.example` using a DNS challenge.
1. They provide a challenge record, which provides a name and value. You then
   create new DNS `TXT` record in the Route53 hosted zone with those
   parameters.
1. Wait for Route53 to roll out those changes. This takes several tens of
   seconds to a couple minutes.
1. Notify Lets Encrypt that you've made the changes. They query the DNS server
   to check that the value they expect is there.
1. If they succeed, you can then generate a certificate signing request (CSR)
   for the domain.
1. Submit the CSR to LetsEncrypt. In return, they will provide
   you with a real actual signed certificate for your domain.
1. Upload that certificate to IAM's certificate management service.
1. Update the ELB's 443 listener to use the IAM certificate. This can also take
   a few seconds, so wait for that to finish.
1. Delete any old certificates from IAM, we won't be needing them any more, and
   it's good to be tidy.
1. Finally, delete the TXT record.

Whew, that's a lot of bookkeeping. There's another step I left out, too: You
need to make a private key, and provide it to the LetsEncrypt client on
subsequent certificate requests. And since it is a private key, it is a good idea
to keep it encrypted, and your updating process will need access to it. My
solution was to encrypt it using AWS' built-in [Key Management Service][KMS],
which allows my EC2 instances that will be performing the steps to decrypt the
private key without needing the decryption token directly.

This was a lot of learning for me, and I've captured everything I've learned as
a Ruby script: [github.com/paul/letsencrypt-route53][letsencrypt-route53]. I
don't think it's worthy of being a gem, in fact, you should probably not even
copy it verbatim. Feel free to take it and modify it to fit your own needs, it
should provide a nice starting point.

I've also included a script that checks the certificate expiry for a domain,
and an example rake task. It should be trivial to incorporate into an
ActiveJob, or cron task, or however else you feel like updating your
certificates.

I'm also excited to hear how people are using this, so please feel to contact
me on twitter or email, or open an Issue or PR on that repo if I screwed up
something obvious.


[lets-encrypt]: https://letsencrypt.org
[DNS challenges]: https://community.letsencrypt.org/t/dns-challenge-is-in-staging/8322
[Route53]: https://aws.amazon.com/route53/
[KMS]: https://aws.amazon.com/kms/
[letsencrypt-route53]: https://github.com/paul/letsencrypt-route53
