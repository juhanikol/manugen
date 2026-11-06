<picture></picture>

# MANUgen

A local AI assistant for manufacturing teams. A worker describes an observation in their own words. MANUgen prepares a structured draft. A person reviews, corrects and approves it. Teams can define their own workflows and fields.

**[Explore MANUgen in Finnish](https://juhanikol.github.io/manugen/)** **[Explore MANUgen in English (compacted)](https://juhanikol.github.io/manugen/en/)**· **[Windows releases](https://github.com/juhanikol/manugen/releases)**

## Inside the application

The user works in a browser window. A local backend runs the workflow steps. A local llama.cpp server runs the language model. Nothing is sent to a cloud service. Approved records can be exported to Excel.

MANUgen was developed as part of a thesis project at Savonia University of Applied Sciences.

## Machining knowledge base

A knowledge base prepared for machining is available to the language model. It is built from Sandvik Coromant learning material and used with permission for non-commercial pilot use in the SIX Manugenius project. It is delivered on request to pilot participants as a separate package. The installer itself ships with an empty knowledge base. Terms: [licenses/content/sandvik-coromant-NOTICE.txt](licenses/content/sandvik-coromant-NOTICE.txt). Request: juhani.kolehmainen@edu.savonia.fi.

## Where to find what

| Location                                                 | Contents                                                                      |
| -------------------------------------------------------- | ----------------------------------------------------------------------------- |
| [Product site](docs/)                                     | Finnish introduction, installation guide, examples and brand assets           |
| [Releases](https://github.com/juhanikol/manugen/releases) | Version notes, Windows installer, checksums and file manifest                 |
| [IT guide](IT-GUIDE.md)                                   | How the installation works: options, network, data, security and requirements |
| [File list](FILES.md)                                     | Every file in this repository and what it is for                              |
| [LICENSE](LICENSE)                                        | MANUgen pilot and usage terms                                                 |

This repository holds the installer script, the scripts that run on the user's computer, the default settings and the licenses. The application source code is not published.

## Features - Brief look

The day with a different problems and a different tools.

You start your day with having problems on the machine floor. Milling parts are not as expected - they need more work. Only problem in this situation is that even more of a task is to fill deviation forms, figure out what to answer to each form field, explain tool usage and wear, and after all that walk to office explaining why the parts are not manufactured in time.

### Solution: Report with your own words

-> generate report -> verify and save -> let the people in the office read the generated report

![your description and generate report](assets/start_processing.gif)

### You can change the values if you forgot to describe all the necessary fields

![change values](change_value.gif)

### You can check what the AI offers for solution or what is infered from you description

![review AI notes](review_AI_notes.gif)

### But you are unsure about the solution AI offered, so you decide to check what is the reference for the suggestion

![look used citations](used_citations.gif)

### Everything looks fine or none of the fields needs changing. Just save.

![save ticket](save_ticket.gif)

### Day continues

You continue you day and as a senior engineer you have the luxury of sitting down behind the desk. But today - as always at the end of the month. You are required to report the handwritten shipping manifests to the system. Manager need those and you have to type those in.

### Another task - another workflow - just choose which to use

![choose workflow](choose_workflow.gif)

Not all things cannot be turned to workflows. However all the tasks you need to perform are governed by your domain. Maybe company have guidelines, instructions, steps-to-follow. Or your domain is so specific that there are simply too specific information and searching the answer to some problem is exhausting. Maybe it slipped your mind - you are sure that just yesterday you searched the answer to the same question.

But you were smart and gave the AI all the data you use - even the sensitive guidelines - the MANUgen is in restricted network with no internet access or you work specifically offline for security reasons.

### Ask something about the data stored in the system

![use_knowledge_for_answers](use_knowledge_for_answers.gif)

## Verify the used data

You are smart and you also check what the references are

![review_used_citations.gif](review_used_citations.gif)

Sometimes you need to go back to what you have done. Thankfully the MANUgen feels already familiar and everything is there where you expect it to be.

![familiar_tools.gif](familiar_tools.gif)
