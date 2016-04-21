
# Let's Encrypt + Route53 + Ruby = Yay!

These days HTTPS is a basic requirement, even for a simple side-project.
Luckily, [Let's Encrypt][lets-encrypt] is out of beta, and had decent libraries
for most languages.  As with everything encryption-related, though, there's a
bit of a learning curve. The typical flow to obtain a certificate looks like this:

1. Tell LetsEncrypt.org that you'd like to protect the domain at
   `myawesomeblog.example`.
1. They provide a challenge, which is a file that you put at a specific
   location with secret contents, and you configure your web server to host
   that file at that domain, to prove that you control it.
1. Once you have that complete, you notify LetsEncrypt that you're ready, and
   they should come look for the file.
1. If they succeed, you can then generate a certificate signing request (CSR)
   for the domain, and provide it to LetsEncrypt. In return, they will provide
   you with a signed certificate for your domain.
1. Finally, you can provide your web server with that certificate, and voilà,
   you now have a site that gets an A+ on [SSL Labs' test][ssl-labs] for free!

This is a pretty involved process, so they provide a client that automagically
does everything for you... including automatically reconfiguring and restarting
your web server! While I'm sure its fine, it makes me nervous as hell, and I
like having more control over what's going on. Additionally, for this project,
I'm hosting it on EC2 behind an ELB that's doing the termination, with two
load-balanced instances in an auto-scaling group (technical blog post
forthcoming). If the LetsEncrypt client decides that its time to update the
cert, and makes the changes on only one host, what happens if the LetsEncrypt
check gets load-balanced to the other host? Finally, they certificate is only
good for 90 days, LetsEncrypt expects you to automate the updating process,
which to me seems to compound the probability that the automagic process would
screw up your web server configs.

Luckily, LetsEncrypt rolled out public support for [DNS challenges][] a few
months ago. This process works basically the same way, but instead of putting
the provided file contents in a known location on your web server in step 2,
you simply create a TXT DNS record for the domain you want the certificate for.
This solves my load-balancing problem quite nicely, because any host can update
the DNS record, and its global. All you need is a DNS provider that provides an
API to create the records. By taking another step into the AWS lock-in,
[Route53][] provides such a service.

However, by doing so, we're adding a few more steps to the process above:

1. Tell LetsEncrypt.org you want to protect a domain with a DNS record.
1. The provide you a challenge record.
1. Use Route53 to add a TXT record with the name & value provided in the challenge.
1. Wait for Route53 to roll out those changes. This takes several tens of seconds.
1. When its done, tell LetsEncrypt you're ready for them to verify.
1. Generate the CSR, get a certificate.
1. Upload that certificate to IAM's certificate manager.
1. Update the ELB's listener with the new IAM certificate
1. Wait for the ELB to update. This can take a few seconds.
1. Delete any old certificates from IAM, we won't be needing them any more, and
   its good to be tidy.
1. Finally, delete the TXT record.

Whew, that's a lot of bookkeeping. There's another step I left out, too: You
need to make a private key, and provide it to the LetsEncrypt client on
subsequent certificate requests. And since its a private key, its a good idea
to keep it encrypted, and your updating process will need access to it. My
solution was to encrypt it using AWS' built-in [Key Management Service][KMS],
which allows my EC2 instances that will be performing the steps to decrypt the
private key without needing the decryption token directly.

This was a lot of learning for me, and I've captured everything I've learned at
a Ruby script: [https://github.com/paul/letsencrypt-route53][]. I don't think
its worthy of being a gem, in fact, you should probably not even copy it
verbatim. Feel free to take it and modify it to fit your own needs, it should
provide a nice starting point.

I've also included a script that checks the certificate expiry for a domain,
and an example rake task. It should be trivial to incorporate into an
ActiveJob, or cron task, or however else you feel like updating your
certificates.

I'm also excited to hear how people are using this, so please feel to contact
me on twitter or email, or open an Issue or PR on that repo if I screwed up
something obvious.


[lets-encrypt]: https://letsencrypt.org
[ssl-labs]: https://www.ssllabs.com/ssltest/
[DNS challenges]: https://community.letsencrypt.org/t/dns-challenge-is-in-staging/8322
[Route53]: https://aws.amazon.com/route53/
[KMS]: https://aws.amazon.com/kms/
