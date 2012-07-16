_           = require "underscore"
async       = require "async"
colors      = require "colors"
progress    = require "progress"

models      = require "./models"

harvard_courses = _.uniq(["Study Abroad in Zanzibar, Tanzania:  Resilience and Transformation", "The Harlem Renaissance", "Study Abroad in Kisumu, Kenya: Innovations, Technologies, and Health Transformations in Africa", "Environmental Crises and State Collapse: Lessons from the Past", "Study Abroad in Scandinavia: Viking Studies\u2014History and Archaeology", "Field School in Archaeology and Paleoecology at the Harvard Forest: Archaeology, Ecology, Sustainability, and Cultural Landscapes", "Icons: A Material History of Harvard", "Introduction to Social Anthropology", "Anthropology and Film", "Constructing Childhood: An Introduction to the Anthropology of Children", "The Anthropology of Water", "Introduction to Irish Myth, Folklore, and Music", "Summer Seminar\u2014Myth and Poetry in Greece and Rome", "Introduction to Acting", "Acting Workshop: Developing a Character", "Acting Workshop: Shakespeare", "Acting Workshop: Comedy", "Intermediate Acting", "Improvisational Acting", "Directing", "Performing Musical Theater", "Modern Dance Technique and Choreography", "Public Speaking", "Study Abroad in Kyoto, Japan: Introduction to the Study of East Asian Religions", "Principles of Economics", "Principles of Economics: Microeconomics", "Principles of Economics: Macroeconomics", "Introduction to Managerial Finance", "Introduction to Capital Markets and Investments", "Microeconomic Theory", "Macroeconomic Theory", "Introduction to Econometrics", "Money, Financial Institutions, and Markets", "International Corporate Governance", "International Monetary Economics", "International Trade and Commercial Policy", "Organizations, Management Behavior, and Economics", "Study Abroad in Venice, Italy: Corporate Finance", "Financial Accounting", "Managerial Accounting", "Financial Strategy and Behavioral Finance", "Capital Markets and Investments", "Study Abroad in Venice, Italy: Redeeming Keynes", "Derivatives and Risk Management: Analytics and Applications", "The Global Financial Crisis", "The Bible in the Humanities and the Arts", "Utopia and Anti-Utopia", "Study Abroad in Venice, Italy: Interracial Literature", "Shakespeare", "The Enlightenment Invention of the Modern Self", "Tragedy: Ancient to Modern", "Study Abroad in Venice, Italy: American Literary Expatriates in Europe", "Twentieth- and Twenty-first Century American Poetry", "Wit and Humor", "The Short Story", "Adolescent Literature", "Twentieth-Century Literature: Modernism and Postmodernism", "Detective Fictions", "Financial Management of Nonprofit Organizations", "Introduction to Political Philosophy", "Introduction to Comparative Politics", "Introduction to American Government", "Introduction to International Relations", "Summer Seminar\u2014International Law and Human Rights", "Pathways to Democracy", "State Formation and Society in Modern Europe", "The Politics of Non-Governmental Organizations", "Intellectual Property", "The Political Economy of Russia and China", "Global Energy and Environmental Politics", "Crime and the Constitution", "War Crimes, Genocide, and Justice", "Globalization and US National Security", "Rationalist Sources of International Conflict and War", "International Law", "International Law: Theory and Research", "Study Abroad in Venice, Italy: International Oil Politics from the 1970s to the Present", "Nuclear Weapons and International Security", "American Foreign Policy", "International Conflict and Cooperation", "Summer Seminar\u2014Rebels with a Cause: Tiananmen in History and Memory", "The Middle Ages in History and Film", "History of the Book, From Gutenberg to E-Readers", "Reform, Republic, Terror, and Empire: The French Revolution, 1787-1804", "New England and the American Nation", "The Rhetoric of Freedom in America", "Summer Seminar\u2014The Holocaust in History, Literature, and Film", "The American Revolution", "The Old South", "Study Abroad in Kyoto, Japan: Japan\u2014Tradition and Transformation", "The Middle East: Rapprochement and Coexistence", "Perspectives on Islam: Religion, History, and Culture", "Study Abroad in Venice, Italy: A History of Consumption", "The Cold War", "From Cold War to Global Terror: World History from 1945 to the Present", "Summer Seminar\u2014Rome and Saint Peter's", "Study Abroad in Venice, Italy:  Leonardo da Vinci", "The Architecture of Boston", "Summer Seminar\u2014On the Witness Stand: Scientific Evidence in the American Judicial System", "Study Abroad in Cambridge, England:  Science, Medicine, and Religion in the Age of Skepticism", "Minds and Machines: Robots, Cyborgs, and Computers in History", "Introduction to Graduate Research Methods and Scholarly Writing in the Humanities", "The Science of Language: An Introduction", "Introduction to Historical Linguistics", "Summer Seminar\u2014Experimental Fiction", "Study Abroad in Greece: Cross-Cultural Contact Between East and West from Ancient Times to the Present", "Reality, Desire, and the Epic Form: Homer, Dante, and Joyce", "Study Abroad in Aix-en-Provence, France: The Arab World and France, Textual Encounters", "Study Abroad in Aix-en-Provence, France:  The Arab and European Mediterranean from Colonial to Postcolonial", "Introduction to Museum Studies", "Graduate Research Methods and Scholarly Writing in Museum Studies", "Fundamentals of Music", "Traditional Music of the Silk Road", "Intensive Ottoman and Turkish Summer School in Turkey", "Field School and Education Program for Ashkelon Excavations: The Leon Levy Expedition", "The Age of R\u016bm\u012b: Knowledge and Patronage Through Period Pieces", "Introduction to Philosophy", "Deductive Logic", "Philosophy in the Public Sphere: Philosophers as Public Intellectuals", "Philosophy of Mind and the Brain Sciences", "Introduction to Biomedical Ethics", "Introduction to Psychology", "Behaviorism and Behavior Modification", "Summer Seminar\u2014The Insanity Defense", "Health Psychology: Connecting Mind and Body in Illness and Wellness", "The Psychology of Emotional, Behavioral, and Motivational Self-Regulation", "Abnormal Psychology", "The Aging Mind and Body", "Psychology of Diversity", "Why People Change: The Psychology of Influence", "Law and Psychology", "Study Abroad in Venice, Italy: The Contested Bible\u2014The Sacred-Secular Dance", "Summer Seminar\u2014Psychology of Religion", "World Religions", "Religion and Animals", "Literature of Journey and Quest", "Islam: Fundamentals of Thought and Practice", "Nordic Cinema", "Study Abroad in Scandinavia: Viking Studies\u2014Lore and Literature", "Graduate Research Methods and Scholarly Writing in the Social Sciences: Psychology and Anthropology", "Graduate Research Methods and Scholarly Writing in the Social Sciences: Government and History", "Introduction to Sociology: Society and Culture", "Study Abroad in Venice, Italy: Immigration and Multiculturalism in Venice", "Globalization and Global Justice", "Social Development in Pakistan", "Introduction to Quantitative Methods", "Fundamentals of Biostatistics", "Study Abroad in Shanghai, China: Vital Statistics for Life and Medical Science", "Summer Seminar\u2014Gender, Race, and Ethics in the Twenty-First Century", "Women and Television", "Interpreting South Asian Women's Lives", "When The Princess Saves Herself: Gender and Retold Fairy Tales", "Feminist Theater", "Icons of Masculinity on Film", "Freud, Sex, and Gender", "Beginning Ukrainian", "Ukrainian for Reading Knowledge", "Twentieth-Century Ukrainian Literature: Rethinking the Canon", "Contemporary Ukraine: History, Geography, and Political Thought", "Drawing Into Painting", "Summer Seminar\u2014The Book as Art: Working with Letters, Ink, and Paper", "Mixed Media", "Works on Paper", "Film History and Social History: American Dreams and Nightmares 1933-1956", "Nazi Cinema: Film and Propaganda", "Scrutinizing the American Environment: The Art, Craft, and Serendipity of Acute Observation", "Art and Technique of Fiction Film Directing", "Cinematic Vision: Scriptwriting for Production", "Crucial Issues in Landscape Creation and Perception", "Study Abroad in Venice, Italy: Beginnings and Endings in the Fiction Film\u2014The Case of Modern Italian Cinema", "Study Abroad in Korea:  Engaging Korean Culture Through Korean Cinema", "Principles of Economics", "Principles of Economics: Microeconomics", "Principles of Economics: Macroeconomics", "Introduction to Managerial Finance", "Introduction to Capital Markets and Investments", "Microeconomic Theory", "Macroeconomic Theory", "Introduction to Econometrics", "Money, Financial Institutions, and Markets", "International Corporate Governance", "International Monetary Economics", "International Trade and Commercial Policy", "Organizations, Management Behavior, and Economics", "Study Abroad in Venice, Italy: Corporate Finance", "Financial Accounting", "Managerial Accounting", "Financial Strategy and Behavioral Finance", "Capital Markets and Investments", "Study Abroad in Venice, Italy: Redeeming Keynes", "Derivatives and Risk Management: Analytics and Applications", "The Global Financial Crisis", "Principles of Finance", "The International Economy and Business", "Financial Statement Analysis", "Business Analysis and Valuation", "Corporate Finance", "International Corporate Finance", "Organizational Behavior", "Managing Yourself and Others", "Principles and Lessons on Leadership", "Negotiation and Organizational Conflict Resolution", "Strategic Management", "Corporate Strategy", "Electronic Commerce Strategies", "Systems Thinking", "Applied Corporate Responsibility", "Corporate Governance", "Emerging Markets in the Global Economy", "Cross-Border Innovation", "Judgment and Decision Making", "Marketing Management", "International Marketing", "Introduction to Scientific Computing", "Great Ideas in Computer Science with Java", "Video Field Production", "Building Dynamic Websites", "Intensive Introduction to Computer Science Using Java", "Communication Protocols and Internet Architectures", "Computational Real-Time Multibody Dynamics and Kinematics", "Tissue Engineering for Clinical Applications", "Introduction to Fabrication of Microfluidic Devices", "Human Factors in Information Systems Design", "Mathematical Models and Expressions", "Precalculus Mathematics", "Calculus I", "Calculus II", "Calculus I and II", "Multivariable Calculus", "Linear Algebra and Differential Equations", "Spaces, Mappings, and Mathematical Structures: An Introduction to Proof", "Graph Theory: Investigating the Mathematical Process", "Math For Teachers: An Algebraic View of Geometry", "Mathematics Review for the GMAT and GRE", "Introduction to Quantitative Methods", "Fundamentals of Biostatistics", "Study Abroad in Shanghai, China: Vital Statistics for Life and Medical Science", "Space Exploration and Astrobiology: Planets, Moons, Stars, and the Search for Life in the Cosmos", "Fundamentals of Contemporary Astronomy: Stars, Galaxies, and the Universe", "Introductory Biology", "Principles of Biochemistry", "Principles and Techniques of Molecular Biology", "Principles of Genetics", "Neurobiology", "Genome and Systems Biology", "Marine Life and Ecosystems of the Sea", "Study Abroad in Bangalore, India: Supervised Reading and Research in Quantitative Life Sciences", "Study Abroad in Tokyo, Japan (RIKEN): Laboratory Research in Neurobiology", "Study Abroad in Yokohama, Japan (RIKEN): Reading and Research in Immunology", "Study Abroad in Shanghai, China: Supervised Laboratory Research in the Life Sciences", "Study Abroad in Shanghai, China: Living Science\u2014Biology, the Self, and the World", "Study Abroad at Oxford: Darwin and the Origins of Evolutionary Biology", "Study Abroad at Oxford: Darwin and Contemporary Evolutionary Biology", "Stem Cell and Regenerative Biology", "Study Abroad in Tokyo, Japan (RIKEN): The Collective Brain", "Study Abroad in Yokohama, Japan (RIKEN): International Symposium on Immunology", "Feast and Famine: The Microbiology of Food", "Imaging in Biology", "Graduate Research Methods and Scholarly Writing in the Biological Sciences", "Medical Genomics and Genetics", "Graduate Research Methods and Scholarly Writing in Biotechnology", "General Chemistry", "Organic Chemistry", "Experimental Chemistry", "Environmental Management", "Global Climate Change: The Science, Social Impact, and Diplomacy of a World Environmental Crisis", "Study Abroad in Venice, Italy: Earth's Climate\u2014Past, Present, and Future", "Fundamentals of Ecology", "Environmental Economics", "Graduate Research Methods and Scholarly Writing in Environmental Management", "Critical Analysis of Environmental Systems", "Capstone Projects in Sustainability and Environmental Management", "Principles of Physics", "Elementary Arabic", "Intermediate Modern Standard Arabic", "Introduction to Irish Myth, Folklore, and Music", "Elementary Modern Chinese I, II", "Elementary Modern Chinese I", "Intermediate Modern Chinese", "Study Abroad in Beijing, China: Intermediate Modern Chinese", "Study Abroad in Beijing, China: Advanced Modern Chinese", "Study Abroad in Beijing, China: Advanced Readings in Modern Chinese", "Study Abroad in Beijing, China: Advanced Writing in Modern Chinese", "Study Abroad in Kyoto, Japan: Introduction to the Study of East Asian Religions", "Beginning French", "French for Reading Knowledge", "Intermediate French", "Oral Expression: Le Fran\u00e7ais parl\u00e9", "Study Abroad in Paris, France: Paris and Its Revolutions", "Beginning German", "Introduction to German for Reading Knowledge", "Study Abroad in Munich: German Language and Culture", "Beginning Greek", "Intermediate Greek: Pagan and Christian Rhetoric in the Late Empire", "Two Tragic Women: Antigone and Medea", "Beginning Hindi", "Beginning Italian", "Study Abroad in Venice, Italy: Beginning Italian", "Elementary Japanese I, II", "Practical Japanese", "Intermediate Japanese", "Beginning Latin", "Virgil:", "Beginning Portuguese", "Beginning Russian", "Beginning Sanskrit", "Beginning Spanish", "Intermediate Spanish", "Study Abroad in Buenos Aires: Spanish Language and Latin American Culture", "Oral Expression: El espa\u00f1ol hablado", "Study Abroad in Barcelona, Spain: Barcelona,", "Study Abroad in Chile: Public Space in Private Times in Latin American Art and Literature", "Study Abroad in Chile: Cultural Production and Social Transformation in Modern Chile", "Beginning Tamil", "Beginning Ukrainian", "Ukrainian for Reading Knowledge", "Twentieth-Century Ukrainian Literature: Rethinking the Canon", "Contemporary Ukraine: History, Geography, and Political Thought", "Beginning Fiction", "Beginning Poetry", "Beginning Screenwriting", "Advanced Fiction: The Novel", "Advanced Fiction: Short Stories", "Advanced Creative Nonfiction", "Advanced Screenwriting", "Legal Writing", "Effective Business Communication", "Cross-Cultural Expository Writing", "Writing and Literature", "Writing about Science", "Writing about Social and Ethical Issues", "The Essay", "Writing About Art", "Business Rhetoric", "Advanced Essay Writing", "Art of Noticing", "Multimedia Communication: Introduction to Digital Storytelling", "Basic Journalism", "Basic Feature Writing", "Graduate Journalism Proseminar: Writing and Reporting", "Feature Writing", "News Reporting for the Web, Print, and Other Platforms", "The Global Journalist"])
bar = new progress "Importing [:bar] :percent", total: harvard_courses.length + models.DORMS.length, width: 50

itr = (flag) ->
  return (name, cb) ->
    models.Group
      .findOne()
      .where("name", name)
      .run (err, doc) ->
        if doc
          bar.tick()
          cb err
        else
          group = new models.Group()
          group.name = name
          group.flag = "harvard-#{flag}"
          group.save (err, dorm) ->
            bar.tick()
            cb err

async.parallel [
  (p_callback) ->
    async.forEach harvard_courses, itr("course"), p_callback
  (p_callback) ->
    async.forEach models.DORMS, itr("dorm"), p_callback
],
(err) ->
  console.log("\n")
  if err
    console.log "Bootstrap FAILED: ".red
    console.log err
    process.exit(1)
  else
    console.log "Bootstrap OK".green
    process.exit(0)