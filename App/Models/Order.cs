using System;

namespace App.Models
{
    public class Order
    {
        public Guid Id { get; set; }
        public decimal Value { get; set; }
        public DateTime CreatedAt { get; set; }

        public Order(decimal value) 
        {
            Id = Guid.NewGuid();
            Value = value;
            CreatedAt = DateTime.Now;   
        }    
    }
}