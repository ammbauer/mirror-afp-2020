{% extends "base.tpl" %}

{% block headline %}
<font class="first">U</font>pdating
<font class="first">E</font>ntries
{% endblock %}

{% block content %}
<table width="80%" class="descr">
  <tbody>
    <tr><td>

<h2>Change</h2>
<p>
The Archive of Formal Proofs is an online resource and therefore
more dynamic than a normal scientific journal. Existing entries
can and do evolve and can also be updated significantly by their
authors.
</p>
<p>
This conflicts with the purpose of archiving and preserving
entries as they have been submitted and with the purpose of 
providing a clear and simple interface to readers.
</p>
<p>
The AFP deals with this by synchronizing such updates with
Isabelle releases:
</p>
<ul>
<li>
The entries released and visible on the main site are always
working with the most recent stable Isabelle version and do not
change.
</li>
<li>
In the background, the archive maintainers evolve all entries to
be up to date with the current Isabelle development
version. Authors can contribute changes to this version which is
available as a <a
href="https://bitbucket.org/isa-afp/afp-devel/">bitbucket
mercurial repository</a> or as tar.gz package on the <a href="download.shtml">
download page</a>.
</li>
<li>
When a new Isabelle version is released, the above mentioned
development version of AFP is frozen and turns into the main
version displayed on the front page. Older versions (including the
original submission) of all entries are archived and remain
accessible.
</li>
</ul>

<h2>If you are an author</h2>

<p>
The above means that if you are an author and would like to
provide a new, better version of your AFP entry, you can do so.
</p>
<p>
To achieve this, you should base your changes on the <a
href="https://bitbucket.org/isa-afp/afp-devel/">mercurial 
development version</a>
of your AFP entry and test it against the current <a
href="http://isabelle.in.tum.de/devel/">Isabelle development
version</a>.
</p>
<p>
If you would like to get write access to your entry in the 
mercurial repository or if you need
assistance, please contact the <a href="about.shtml#editors">editors</a>.
</p>

    </td></tr>
  </tbody>
</table>
{% endblock %}

