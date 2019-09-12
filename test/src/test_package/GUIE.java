package test_package;

import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.ArrayList;
import java.util.List;

import javax.swing.BoxLayout;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;

public class GUIE implements ActionListener{

	JButton button;
	JFrame gui;
	
	//The list's that will hold the input of the user's GUI text fields
	ArrayList<JTextField> LengthText = new ArrayList<JTextField>();
	ArrayList<JTextField> AngleText = new ArrayList<JTextField>();
	
	
	//the method that creates the GUI itself
	public void createGUI() {
		gui = new JFrame("Vector Addition Program");
		gui.setSize(500, 500);
		JPanel basePanel = new JPanel();
		BoxLayout bxl = new BoxLayout(basePanel, BoxLayout.Y_AXIS);
		basePanel.setLayout(bxl);
		gui.setContentPane(basePanel);

		//Create the vector text fields and angle text fields in the GUI
		for(int x = 0; x < 4; x++) {
			
			JPanel panel = new JPanel(new FlowLayout());
			basePanel.add(panel);
			JLabel v1 = new JLabel("Vector " + (x+1) + " - Length:");
			panel.add(v1);
			JTextField v1LengthText = new JTextField();
			v1LengthText.setPreferredSize(new Dimension(100, 20));
			LengthText.add(v1LengthText);
			panel.add(v1LengthText);
			JLabel v1Angle = new JLabel("Angle:");
			panel.add(v1Angle);
			JTextField v1AngleText = new JTextField();
			v1AngleText.setPreferredSize(new Dimension(100, 20));
			AngleText.add(v1AngleText);
			panel.add(v1AngleText);
		}
	
		
		
		//create the add vectors button and assign a listener to it
		button = new JButton("Add Vectors");
		button.addActionListener(this);
		basePanel.add(button);
		
		
		gui.setVisible(true);
	}

	//this method is called whenever a button is pressed
	@Override
	public void actionPerformed(ActionEvent e) {
		//check if the button pressed is the button we want
		if(e.getSource() == button) {
			
			//list's that will hold the X and Y of each vector
			List<Double> sigmaX = new ArrayList<Double>();
			List<Double> sigmaY = new ArrayList<Double>();
			
			//loop through all the text fields and take the length and angle of each vector. Than use maths and get the X and Y of each vector
			for(int x = 0; x < 4; x++) {
				//if the text field is empty, don't add it to the calculations
				if(LengthText.get(x).getText().isEmpty()) {
					 
				} else {
					sigmaX.add(createVectorX(LengthText.get(x).getText(), AngleText.get(x).getText()));
					sigmaY.add(createVectorY(LengthText.get(x).getText(), AngleText.get(x).getText()));
				}
			}
			
			//get the sum of all the X and Y's of the vectors
			double sumOfX = sumifier(sigmaX);
			double sumOfY = sumifier(sigmaY);
			
			
			double divide = sumOfY/sumOfX;
			double angleOfVector = Math.atan(divide);
			double lengthOfVector = Math.sqrt(sumOfX*sumOfX + sumOfY*sumOfY);
			
			double degreesToAdd = addDegrees(sumOfX, sumOfY);
			
			gui.getContentPane().removeAll();
		
			double answerAngle = Math.toDegrees(angleOfVector) + degreesToAdd;
			
			JLabel answerLabel = new JLabel("The angle of the new Vector is: " + String.format("%.2f", answerAngle) + " and the length of the new Vector is: " + String.format("%.2f", lengthOfVector));
			gui.add(answerLabel);
			gui.validate();
			gui.repaint();

			
			}
		
	}
	
	//Use the length and angle to get the X of a vector
	public double createVectorX(String length, String angle) {
		double vectorLength = Double.parseDouble(length);
		double vectorAngle = Double.parseDouble(angle);
		
		double VectorX = vectorLength*Math.cos(Math.toRadians(vectorAngle));
		return VectorX;
		
		
	}
	
	//Use the length and angle to get the Y of a vector
	public double createVectorY(String length, String angle) {
		double vectorLength = Double.parseDouble(length);
		double vectorAngle = Double.parseDouble(angle);
		
		double VectorY = vectorLength*Math.sin(Math.toRadians(vectorAngle));
		
		return VectorY;
		
	}
	
	//Take a list and sum up all the items inside. Sadly this is not python and there is no list.sum
	public double sumifier(List<Double> list) {
		double sum = 0;
		for(int x = 0; x < list.size(); x++) {
			sum+=list.get(x);
		}
		return sum;
	}
	
	//Check in what part of the XY chart the vector is in and add the amount of degrees necessary
	public double addDegrees(double x, double y) {
		
		double degreesToAdd = 0;
		
		//if vector is on left
		if(x < 0) {
			degreesToAdd = 180;
		}
		
		//if vector is on bottom right
		if(x > 0) {
			if(y < 0) {
				degreesToAdd = 360;
			}
		}
		
		return degreesToAdd;
		
	}
	
}
