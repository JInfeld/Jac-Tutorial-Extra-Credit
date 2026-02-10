## Name
Jordan Infeld 42821274

## Added feature
 My feature adds priority for the TODO list from the original categories (HEALTH, WORK, PERSONAL, OTHER, SHOPPING). The TODOs are reordered based on category priority and the user can change the priority of each category based on their current needs. 

## Relevant Code
12-20: categories are given initial priority. 

120-130: todos are ordered in order based on current priority. 

132-146: functions to change the priority of categories up or down. 

193-212: button functionality to change priorities. 


These sections of code define a priority attribute with each todo based on the category. The categories are moved up or down based on a changing priority that the user can control. Once sorted, each todo is displayed in order of priority.

## Project Structure

```
my-todo-app/
├── jac.toml              # Project configuration
├── main.jac              # Main application entry
├── components/           # Reusable components
│   └── Button.cl.jac     # Example Jac component
├── assets/               # Static assets (images, fonts, etc.)
└── build/
```      

## Getting Started

Start the development server:

```bash
jac start main.jac
```

