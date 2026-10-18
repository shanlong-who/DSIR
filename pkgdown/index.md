<div class="dsi-landing">

<section class="dsi-hero" aria-labelledby="dsi-title">
<div class="dsi-hero-copy">
<p class="dsi-brand">DSIR</p>
<p class="dsi-brand-name">Data Science Infrastructure for Global Health</p>
<h1 id="dsi-title">From Global Health Data to Clear Insights</h1>
<p class="dsi-lead">DSIR is an open-source R package that simplifies access to global health data, supports consistent data processing, and provides reusable tools for analysis and visualization.</p>
<div class="dsi-actions">
<a class="dsi-button dsi-button-primary" href="#core-capabilities">Explore Features</a>
<a class="dsi-button dsi-button-secondary" href="#getting-started">Get Started</a>
</div>
<div class="dsi-hero-links">
<a href="articles/DSIR.html">Technical Documentation <span aria-hidden="true">&rarr;</span></a>
<a href="https://github.com/shanlong-who/DSIR">GitHub <span aria-hidden="true">&rarr;</span></a>
</div>
<p class="dsi-project-note">Open source &middot; Available on CRAN &middot; MIT licence</p>
</div>

<figure class="dsi-workflow" aria-labelledby="workflow-title">
<figcaption id="workflow-title">A consistent R workflow</figcaption>
<ol>
<li><span class="dsi-step" aria-hidden="true">01</span><div><strong>Access</strong><span>WHO GHO &middot; WHO GHE &middot; UN SDG</span></div></li>
<li><span class="dsi-step" aria-hidden="true">02</span><div><strong>Prepare</strong><span>Clean tables, country codes and data context</span></div></li>
<li><span class="dsi-step" aria-hidden="true">03</span><div><strong>Analyse</strong><span>Health indicators, mortality and progress</span></div></li>
<li><span class="dsi-step" aria-hidden="true">04</span><div><strong>Present</strong><span>Consistent charts and analytical tables</span></div></li>
</ol>
<p>Reusable tools for each stage of your analysis.</p>
</figure>
</section>

<section class="dsi-section dsi-why" aria-labelledby="why-dsir">
<div>
<p class="dsi-eyebrow">The everyday challenge</p>
<h2 id="why-dsir">Why DSIR?</h2>
<p>Health data are spread across platforms, with different table structures and geographical identifiers. Analysts repeatedly retrieve, clean and format data, while keeping their work reproducible and their reports consistent.</p>
</div>
<div class="dsi-why-answer">
<p>DSIR brings commonly used global health data sources and analytical utilities into a consistent R workflow, reducing repetitive data preparation and supporting reproducible analyses.</p>
<p class="dsi-small">For technical teams preparing country comparisons, monitoring indicators and producing public health reports.</p>
</div>
</section>

<section class="dsi-section" aria-labelledby="core-capabilities">
<div class="dsi-section-heading">
<p class="dsi-eyebrow">What you can do</p>
<h2 id="core-capabilities">Core capabilities</h2>
</div>
<div class="dsi-capability-grid">
<article class="dsi-capability">
<p class="dsi-card-number" aria-hidden="true">01 / ACCESS</p>
<h3>Access Global Health Data</h3>
<p>Retrieve observations from WHO Global Health Observatory (GHO), WHO Global Health Estimates (GHE), and UN Sustainable Development Goals (SDG) services. Select countries, years and population breakdowns.</p>
<a href="articles/ghe-xmart.html">Explore WHO data access <span aria-hidden="true">&rarr;</span></a>
</article>
<article class="dsi-capability">
<p class="dsi-card-number" aria-hidden="true">02 / PREPARE</p>
<h3>Harmonize Data</h3>
<p>Work with a consistent cleaned table structure, WHO Member State metadata and country identifiers. Keep additional dimensions and source information when needed.</p>
<a href="reference/bind_indicators.html">See data preparation tools <span aria-hidden="true">&rarr;</span></a>
</article>
<article class="dsi-capability">
<p class="dsi-card-number" aria-hidden="true">03 / ANALYSE</p>
<h3>Analyse Health Indicators</h3>
<p>Use life tables, direct age standardization and measures of annual progress to support mortality analysis and indicator monitoring.</p>
<a href="reference/index.html#demographic-methods">Explore analytical methods <span aria-hidden="true">&rarr;</span></a>
</article>
<article class="dsi-capability">
<p class="dsi-card-number" aria-hidden="true">04 / PRESENT</p>
<h3>Visualize and Present Results</h3>
<p>Apply reusable ggplot2 themes and flextable formatting to create consistent charts and analytical tables for technical reports.</p>
<a href="articles/visualizing-indicators.html">View visualization examples <span aria-hidden="true">&rarr;</span></a>
</article>
</div>
<p class="dsi-context-note">A common table structure does not make indicator definitions or estimation methods comparable. Check source methods, population breakdowns and units before comparing results.</p>
</section>

<section class="dsi-section dsi-applications" aria-labelledby="practical-applications">
<div class="dsi-section-heading">
<p class="dsi-eyebrow">From tools to tasks</p>
<h2 id="practical-applications">Practical applications</h2>
<p>For WHO technical teams and public health researchers working with international health data.</p>
</div>
<ul class="dsi-application-grid">
<li><h3>Monitor health indicators</h3><p>Explore observations across countries and years, keeping population groups and data sources visible.</p></li>
<li><h3>Explore mortality and disease burden</h3><p>Examine WHO estimates by cause, age, sex, country and year.</p></li>
<li><h3>Assess progress towards SDG targets</h3><p>Retrieve health-related SDG series and analyse changes over time.</p></li>
<li><h3>Prepare reproducible reports</h3><p>Reuse data preparation steps, charts and table styles across analytical outputs.</p></li>
</ul>
<p class="dsi-small">These are potential uses of the package, not claims of official adoption by WHO.</p>
</section>

<div class="dsi-section dsi-about-grid">
<section class="dsi-roadmap" aria-labelledby="development-roadmap">
<p class="dsi-eyebrow">Ongoing development</p>
<h2 id="development-roadmap">Development roadmap</h2>
<p>DSIR continues to evolve in response to practical needs in global health data analysis. Future development is planned to include GIS-related functions to support geospatial data processing, mapping and spatial analysis.</p>
<p class="dsi-small">GIS capabilities are a future direction and are not part of the current release.</p>
</section>
<section class="dsi-developer" aria-labelledby="developer">
<p class="dsi-eyebrow">The person behind the project</p>
<h2 id="developer">Developed and maintained by Shanlong Ding</h2>
<p>Technical Officer (Data Analyst)<br>WHO Regional Office for the Western Pacific</p>
<a href="https://github.com/shanlong-who">View GitHub profile <span aria-hidden="true">&rarr;</span></a>
<p class="dsi-small dsi-independence">DSIR is a personally maintained open-source project. It is not an official WHO software product and is not endorsed or published by WHO.</p>
</section>
</div>

<section class="dsi-section dsi-getting-started" aria-labelledby="getting-started">
<div>
<p class="dsi-eyebrow">Start with the package</p>
<h2 id="getting-started">Getting started</h2>
<p>Install DSIR from CRAN, then follow the technical guide for data access, analysis and presentation.</p>
<div class="dsi-install" aria-label="R installation commands">

```r
install.packages("DSIR")
library(DSIR)
```

</div>
</div>
<nav class="dsi-resource-links" aria-label="Documentation and package resources">
<a href="https://CRAN.R-project.org/package=DSIR">CRAN Package <span aria-hidden="true">&rarr;</span></a>
<a href="reference/index.html">Function Reference <span aria-hidden="true">&rarr;</span></a>
<a href="articles/index.html">Tutorials / Articles <span aria-hidden="true">&rarr;</span></a>
<a href="articles/DSIR.html">Full Technical Documentation <span aria-hidden="true">&rarr;</span></a>
<a href="https://github.com/shanlong-who/DSIR#readme">GitHub Repository &amp; Technical README <span aria-hidden="true">&rarr;</span></a>
<a href="news/index.html">Release Notes <span aria-hidden="true">&rarr;</span></a>
</nav>
</section>

</div>
