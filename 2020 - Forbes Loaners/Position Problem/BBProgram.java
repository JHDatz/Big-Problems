
//John Juozitis
//BIG Problems in Math - Baseball Program
import java.io.*;
import java.util.*;

public class BBProgram {	
	public static void main (String args[]) throws Exception {
	
	
	BufferedReader baseballFile = new BufferedReader(new FileReader("info.txt") );
	TreeMap<String, player> player2Data = new TreeMap<String, player>();
	TreeMap<String, TreeMap<Integer, player>> allPlayerData = new TreeMap<String, TreeMap<Integer, player>>();
	int years, age;
	double inn, inn_game;
	double DRS = 0;
	String name, position;
	player temp;
	TreeMap<Integer,player> curr;
	
	while(baseballFile.ready() ) {
		String [] keys = baseballFile.readLine().split(",");	
		name = keys[1];
		years = Integer.parseInt(keys[0].substring(0,4));
		position = keys[2];
		if(!keys[3].contains("NA")) DRS = Double.parseDouble(keys[3].substring(1, keys[3].length() - 1));
		inn = Double.parseDouble(keys[4].substring(1, keys[4].length() - 1));
		inn_game = Double.parseDouble(keys[5].substring(1, keys[5].length() - 1));
		age = Integer.parseInt(keys[6].substring(1, 3));
		temp = new player(years, DRS, age, inn, inn_game, name, position);
		player2Data.put(years + name, temp);
		
		if(allPlayerData.get(name) == null)
		{
			curr = new TreeMap<Integer, player>();
			curr.put(years, temp);
			allPlayerData.put(name, curr);
		}
		else
		{
			curr = allPlayerData.get(name);
			curr.put(years, temp);
			allPlayerData.put(name, curr);	//overwrite old list
			
		}
		

	}
			for(String key: allPlayerData.keySet() ) {
			//for(Integer year2: allPlayerData.get(key).keySet() )
				//System.out.println(key + " " + allPlayerData.get(key).get(year2).getInn_Game());
			//System.out.println(key);
			}
	int count = 0;
	int changeCount = 0;
	TreeMap<Integer,Integer> timeSinceChange = new TreeMap<Integer, Integer>();
	TreeMap<Integer, HashSet<Double>> time2DRS = new TreeMap<Integer, HashSet<Double>>();
	for(String key: allPlayerData.keySet() )
	{
		count++;
		TreeMap<Integer, player> currSet = allPlayerData.get(key);
		int start = currSet.firstKey();
		String tempPos = currSet.get(start).getPosition();
		String newPos = "";
		for(Integer year: currSet.keySet() )
		{
			double IG = currSet.get(year).getInn_Game();
			newPos = currSet.get(year).getPosition(); 
			if(!newPos.equals(tempPos) && (IG > 6.12))
			{
				
			//	System.out.println(key + tempPos + " " + currSet.get(year).getPosition() + " " + currSet.get(year).getDRS() + " " + currSet.get(year).getInn_Game() + " " + currSet.get(year).getAge());
				
				//System.out.println(key + " " + "changed from " + tempPos + "to " + newPos);
				changeCount++;
				int time = year - start; 
				double DRS2 = currSet.get(year).getDRS();
				if(timeSinceChange.get(time) == null) 
					timeSinceChange.put(time, 1);		//counter is 1 for this time
				else
				{
					timeSinceChange.put(time, timeSinceChange.get(time) + 1);	//increase occurrence by one
					
				}
				if(time2DRS.get(time) == null)
				{
					HashSet<Double> tempSet = new HashSet<Double>();
					tempSet.add(DRS2);
					time2DRS.put(time, tempSet);
				}
				else
				{
					HashSet<Double> tempDRSSet = time2DRS.get(time);
					tempDRSSet.add(DRS2);
					time2DRS.put(time, tempDRSSet);
					
				}
				tempPos = newPos;
		//System.out.println(key + player2Data.get(key).getPosition()+ " " + player2Data.get(key).getDRS() +" " +player2Data.get(key).getInn_Game() +" " + player2Data.get(key).getAge());

			}
			
		}
		
	}
	int sum = 0;
	System.out.println("Number of players that changed positions and had inn_game > 6.12:	" + changeCount);
	System.out.println();
	for(Integer key: timeSinceChange.keySet() )
	{
		System.out.print("Years between change: " + key + "		" + "Occurrences: " + timeSinceChange.get(key) + "		");
		sum+= timeSinceChange.get(key);
		int counterDRS = 0;
		double total = 0;

	
		
			HashSet<Double> temp3 = time2DRS.get(key);
			for(Double DRS3: temp3)
			{
				//System.out.print(DRS3);
					total+= DRS3;
					counterDRS++;
			}
			
			//System.out.println("Key " + key + "Total " + total + " " + "Counter " + counterDRS);
		
		
		
		System.out.println("Average DRS: " + total/counterDRS);
		
	}
	System.out.println();
	System.out.println("Sum check: " + sum);
	/*
	for(String key: allPlayerData.keySet() )
		{
			TreeMap<Integer, player> tester = allPlayerData.get(key);
			for(Integer key2: tester.keySet() )
			{
				System.out.print(key + "	");
				System.out.println(key2 + "	" + tester.get(key2).getDRS() );
			}
			
		}
	
	/*
	for(String key: player2Data.keySet() )
	{
		player kewl = player2Data.get(key);
		System.out.print(key + "	");
		System.out.print(kewl.getPosition()  + "	");
		System.out.print(kewl.getDRS()  + "	");
		System.out.print(kewl.getInn()  + "	");
		System.out.print(kewl.getInn_Game()  + "	");
		System.out.println(kewl.getAge() );
	}
	*/
	

	
	
		//System.out.println(key + player2Data.get(key).getPosition()+ " " + player2Data.get(key).getDRS() +" " +player2Data.get(key).getInn_Game() +" " + player2Data.get(key).getAge());
	}

static class player {
	
	int years, age;
	double inn, inn_game, DRS;
	String name, position;
	
	public player (int y, double d, int a, double i, double ig, String n, String p) {

		setYears(y);
		setDRS(d);
		setAge(a);
		setInn(i);
		setInn_Game(ig);
		setName(n);
		setPosition(p);
		
	}	
	public void setYears(int y)
	{
		this.years = y;
	}
	public void setDRS (double d)
	{
		this.DRS = d;
	}
	public void setAge (int a)
	{
		this.age = a;
	}
	public void setInn( double i)
	{
		this.inn = i;
	}
	public void setInn_Game(double ig)
	{
		this.inn_game = ig;
	}
	public void setName (String n)
	{
		this.name = n;
	}
	public void setPosition (String p)
	{
		this.position = p;
		
	}
	// helpers
	public int getYears()
	{
		return years;
	}
	public double getDRS ()
	{
		return DRS;
	}
	public int getAge ()
	{
		return age;
	}
	public double getInn()
	{
		return inn;
	}
	public double getInn_Game()
	{
		return inn_game;
	}
	public String getName ()
	{
		return name;
	}
	public String getPosition ()
	{
		return position;
		
	}	
}

}